#!/usr/bin/env bash
. ./cmd.sh
. ./file_and_dir.sh
. ./sed.sh
. ./log.sh

# reference:
# https://hk.saowen.com/a/4bcd4ff5fbdb05930119ce3c0f2d5c7b8de7200553ab5d1f85492585ee3159db
# https://wiki.mikejung.biz/Kubernetes
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# https://coreos.com/tectonic/docs/latest/tutorials/kubernetes/getting-started.html
# https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/integration
# https://kubernetes.io/docs/tutorials/stateless-application/expose-external-ip-address/
# https://github.com/kubernetes/community/blob/master/contributors/design-proposals/multicluster/federation.md
# https://kubernetes.io/docs/concepts/cluster-administration/network-plugins/
# https://thenewstack.io/hackers-guide-kubernetes-networking/

TMP_DIR=`eval echo ~$USER`

#K8S_VERSION="v1.9.3_coreos.0"
K8S_VERSION=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`
K8S_DNS_SERVICE_IP="8.8.8.8"
K8S_NETWORK_PLUGIN="cni" #cni/kubenet
#K8S_POD_CIDR="192.168.0.0/16"

K8S_TMP_KEY_DIR="${TMP_DIR}/kube-ssl"
K8S_KEY_DIR="/etc/kubernetes/ssl"
K8S_LOG_DIR="/var/log/kubernetes"

K8S_ROOT_KEY="ca"

K8S_API_KEY_CONF="openssl.cnf"
K8S_API_KEY="apiserver"

K8S_WORKER_KEY_CONF="worker-openssl.cnf"
#K8S_WORKER_KEY="<__FQDN__>"

K8S_CALICO_CONF="/etc/kubernetes/cni/net.d/10-calico.conf"
K8S_CNI_BIN="/etc/kubernetes/cni"

KUBECTL_DOWNLOAD="https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
KUBECTL_RUN="/opt/bin/kubectl"

KUBEADM_DOWNLOAD="https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubeadm"
KUBEADM_RUN="/opt/bin/kubeadm"

KUBELET_UNIT="/etc/systemd/system/kubelet.service"

KUBELET_CONF="/etc/kubernetes/kubelet.kubeconfig"

K8S_MANIFEST_DIR="/etc/kubernetes/manifests"
CALICO_KUBE_CONTROLLER_MANIFEST="${K8S_MANIFEST_DIR}/calico-kube-controllers.yaml"
KUBELET_API_MANIFEST="${K8S_MANIFEST_DIR}/kube-apiserver.yaml"
KUBELET_POD_MANIFEST="${K8S_MANIFEST_DIR}/kubernetes.yaml"
KUBELET_PROXY_MANIFEST="${K8S_MANIFEST_DIR}/kube-proxy.yaml"
KUBELET_CONTROLLER_MANIFEST="${K8S_MANIFEST_DIR}/kube-controller-manager.yaml"
KUBELET_SCHEDULER_MANIFEST="${K8S_MANIFEST_DIR}/kube-scheduler.yaml"
KUBELET_POLICY_CONTROLLER_MANIFEST="${K8S_MANIFEST_DIR}/kube-policy-controller.yaml"

KUBELET_API_SECURE_PORT=6443
KUBELET_API_INSECURE_PORT=8080

function create_kube_config() {
  local _content=`cat << EOF
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
  name: scratch

users:
- name: developer
- name: experimenter

contexts:
- context:
    cluster: scratch
  name: dev-one
- context:
    cluster: scratch
  name: dev-two
EOF`

  overwrite_content "${_content}" "${KUBELET_CONF}" "sudo"
}

function set_kubeconfig_cluster() {
  local _master=$1
  local _cluster=$2
  local _option=${3:-}

  if [ "${_option}" = "insecure" ]; then
    sudo kubectl config --kubeconfig=${KUBELET_CONF} set-cluster ${_cluster} \
    --server=http://${_master}:${KUBELET_API_INSECURE_PORT} \
    --insecure-skip-tls-verify && \
    log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[KUBECTL][insecure][set-cluster]" ||
    log "... ${FONT_RED}failed${FONT_NORMAL}" "[KUBECTL][insecure][set-cluster]"
  else
    sudo kubectl config --kubeconfig=${KUBELET_CONF} set-cluster ${_cluster} \
    --server=http://${_master}:${KUBELET_API_INSECURE_PORT} \
    --certificate-authority=${K8S_KEY_DIR}/${K8S_ROOT_KEY}.pem && \
    log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[KUBECTL][secure][set-cluster]" ||
    log "... ${FONT_RED}failed${FONT_NORMAL}" "[KUBECTL][secure][set-cluster]"
  fi
}

function set_kubeconfig_context() {
  local _context=$1

  sudo kubectl config --kubeconfig=${KUBELET_CONF} use-context ${_context} && \
  log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[KUBECTL][set-context]" ||
  log "... ${FONT_RED}failed${FONT_NORMAL}" "[KUBECTL][set-context]"
}

function create_root_keys() {
  sudo openssl genrsa -out ${K8S_ROOT_KEY}-key.pem 2048
  sudo openssl req -x509 -new -nodes -key ${K8S_ROOT_KEY}-key.pem -days 10000 -out ${K8S_ROOT_KEY}.pem -subj "/CN=kube-ca"
}

function create_api_server_keys() {
  local _master=$1 #ip
  local _content=`cat << 'EOF'
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 10.13.0.1
IP.2 = <__MASTER_PUBLIC_IP__>
EOF
`

  overwrite_content "${_content}" "${K8S_API_KEY_CONF}"
  replace_word_in_file "<__MASTER_PUBLIC_IP__>" "${_master}" "${K8S_API_KEY_CONF}"

  sudo openssl genrsa -out ${K8S_API_KEY}-key.pem 2048

  sudo openssl req -new -key ${K8S_API_KEY}-key.pem \
  -out ${K8S_API_KEY}.csr -subj "/CN=kube-apiserver" -config ${K8S_API_KEY_CONF}

  sudo openssl x509 -req -in ${K8S_API_KEY}.csr \
  -CA ${K8S_ROOT_KEY}.pem -CAkey ${K8S_ROOT_KEY}-key.pem -CAcreateserial \
  -out ${K8S_API_KEY}.pem -days 365 -extensions v3_req -extfile ${K8S_API_KEY_CONF}
}

function create_worker_keys() {
  local _worker_ip=$1 #ip
  local _worker_fqdn=${2:-$_worker_ip}

  local _content=`cat << 'EOF'
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name/
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = $ENV::WORKER_IP
EOF
`

  overwrite_content "${_content}" "${K8S_WORKER_KEY_CONF}"

  openssl genrsa -out ${_worker_fqdn}-worker-key.pem 2048

  WORKER_IP=${_worker_ip} \
  openssl req -new -key ${_worker_fqdn}-worker-key.pem -out ${_worker_fqdn}-worker.csr -subj "/CN=${_worker_fqdn}" \
  -config ${K8S_WORKER_KEY_CONF}

  WORKER_IP=${_worker_ip} \
  openssl x509 -req -in ${_worker_fqdn}-worker.csr -CA ${K8S_ROOT_KEY}.pem -CAkey ${K8S_ROOT_KEY}-key.pem \
  -CAcreateserial -out ${_worker_fqdn}-worker.pem -days 365 -extensions v3_req -extfile ${K8S_WORKER_KEY_CONF}
}

function setup_tls_assets() {
  local _master=$1

  create_dir "${K8S_TMP_KEY_DIR}"
  create_dir "${K8S_KEY_DIR}" "sudo"

  pushd ${K8S_TMP_KEY_DIR}

  create_root_keys
  create_api_server_keys ${_master}
#  create_worker_keys ${_worker}

  sudo cp ${K8S_TMP_KEY_DIR}/*.pem ${K8S_KEY_DIR}/
  set_permission "600" "${K8S_KEY_DIR}/*-key.pem" "sudo"
  set_ownership "root" "root" "${K8S_KEY_DIR}/*-key.pem" "sudo"

  popd
}

function setup_calico_service_unit() {
  local _etcd_ip=$1
  local _calico_unit="/etc/systemd/system/calico-node.service"
  local _calico_unit_content=`cat << "EOF"
[Unit]
Description=calico node
After=docker.service
Requires=docker.service

[Service]
User=root
Environment=ETCD_ENDPOINTS=http://<__ETCD_IP__>:2379
PermissionsStartOnly=true
ExecStart=/usr/bin/docker run --net=host --privileged --name=calico-node \\
  -e ETCD_ENDPOINTS=${ETCD_ENDPOINTS} \\
  -e NODENAME=${HOSTNAME} \\
  -e IP= \\
  -e NO_DEFAULT_POOLS= \\
  -e AS= \\
  -e CALICO_LIBNETWORK_ENABLED=true \\
  -e IP6= \\
  -e CALICO_NETWORKING_BACKEND=bird \\
  -e FELIX_DEFAULTENDPOINTTOHOSTACTION=ACCEPT \\
  -v /var/run/calico:/var/run/calico \\
  -v /lib/modules:/lib/modules \\
  -v /run/docker/plugins:/run/docker/plugins \\
  -v /var/run/docker.sock:/var/run/docker.sock \\
  -v /var/log/calico:/var/log/calico \\
  quay.io/calico/node:v3.0.3
ExecStop=/usr/bin/docker rm -f calico-node
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
`
  create_dir "`dirname ${_calico_unit}`"

  overwrite_content "${_calico_unit_content}" "${_calico_unit}" "sudo"

  replace_word_in_file "<__ETCD_IP__>" "${_etcd_ip}" "${_calico_unit}" "sudo"

  sudo systemctl daemon-reload
  sudo systemctl stop calico-node
  sudo systemctl start calico-node
}

function setup_cni_calico_plugin() {
  # Calico secures the overlay network by restricting traffic to/from the pods based on fine-grained network policy.
  local _etcd_host=$1 #ip

  local _calico_download="https://github.com/projectcalico/cni-plugin/releases/download/v2.0.1/calico"
  local _calico_ipam_download="https://github.com/projectcalico/cni-plugin/releases/download/v2.0.1/calico-ipam"

  sudo wget -N -P ${K8S_CNI_BIN} ${_calico_download}
  sudo wget -N -P ${K8S_CNI_BIN} ${_calico_ipam_download}
  set_permission "+x" "${K8S_CNI_BIN}/calico" "sudo"
  set_permission "+x" "${K8S_CNI_BIN}/calico-ipam" "sudo"

  local _content=`cat << EOF
{
    "name": "calico-k8s-network",
    "cniVersion": "0.1.0",
    "type": "calico",
    "etcd_endpoints": "http://${_etcd_host}:2379",
    "log_level": "DEBUG",
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "ipv4_pools": ["192.168.201.0/24"]
    },
    "policy": {
        "type": "k8s"
    },
    "kubernetes": {
        "kubeconfig": "${KUBELET_CONF}"
    }
}
EOF`

  overwrite_content "${_content}" "${K8S_CALICO_CONF}" "sudo"
}

function setup_cni_lo_plugin() {
  # In addition to the CNI plugin specified by the CNI config file, Kubernetes requires the standard CNI loopback plugin.
  wget https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz -P ${TMP_DIR}/cni
  pushd ${TMP_DIR}/cni
  tar -zxvf cni-v0.3.0.tgz
  sudo cp loopback ${K8S_CNI_BIN}
  popd
}

function setup_cni_flannel_network() {
  local _master_host=$1 #ip
  local _etcd_host=$2 #2
  local _flannel_config="/etc/flannel/options.env"
  local _flannel_config_content=`cat << EOF
FLANNELD_IFACE=${_master_host}
FLANNELD_ETCD_ENDPOINTS=http://${_etcd_host}:2379
EOF
`
  local _flannel_unit="/etc/systemd/system/flanneld.service.d/40-ExecStartPre-symlink.conf"
  local _flannel_unit_content=`cat << EOF
[Service]
ExecStartPre=/usr/bin/ln -sf /etc/flannel/options.env /run/flannel/options.env
EOF
`

  create_dir "`dirname ${_flannel_config}`"
  create_dir "`dirname ${_flannel_unit}`"

  overwrite_content "${_flannel_config_content}" "${_flannel_config}"
  overwrite_content "${_flannel_unit_content}" "${_flannel_unit}"

  etcdctl set /coreos.com/network/config "{\"Network\":\"10.12.0.0/16\",\"Backend\":{\"Type\":\"vxlan\"}}"
}

function setup_kubecli() {
#  the command line util to talk to your cluster.

  local _master=$1

  pushd ~
  run_and_validate_cmd "sudo mkdir -p `dirname ${KUBECTL_RUN}`"
  run_and_validate_cmd "sudo curl ${KUBECTL_DOWNLOAD} -o ${KUBECTL_RUN}"
  run_and_validate_cmd "sudo chmod +x ${KUBECTL_RUN}"
  popd

  export KUBERNETES_MASTER=http://${_master}:${KUBELET_API_INSECURE_PORT}
}

function setup_kubeadm() {
#  the command to bootstrap the cluster.

  pushd ~
  run_and_validate_cmd "sudo mkdir -p `dirname ${KUBEADM_RUN}`"
  run_and_validate_cmd "sudo curl ${KUBEADM_DOWNLOAD} -o ${KUBEADM_RUN}"
  run_and_validate_cmd "sudo chmod +x ${KUBEADM_RUN}"
#  run_and_validate_cmd "sudo mkdir -p `dirname ${KUBECTL_RUN}`"
#  run_and_validate_cmd "sudo mv ${KUBECTL} ${KUBECTL_RUN}"
  popd
}

function setup_kubelet() {
# The kubelet is the agent on each machine that starts and stops Pods and other machine-level tasks.
# The kubelet communicates with the API server (also running on the master nodes) with the TLS certificates
# The component that runs on all of the machines in your cluster and does things like starting pods and containers.

  local _master_ip=$1
  local _calico_dir=`dirname ${K8S_CALICO_CONF}`
  local _content=`cat << "EOF"
[Service]
Environment=KUBELET_IMAGE_TAG=<__K8S_VERSION__>_coreos.0
Environment="RKT_RUN_ARGS=--uuid-file-save=/var/run/kubelet-pod.uuid \\
  --volume var-log,kind=host,source=/var/log \\
  --mount volume=var-log,target=/var/log \\
  --volume dns,kind=host,source=/etc/resolv.conf \\
  --mount volume=dns,target=/etc/resolv.conf" \\
ExecStartPre="/usr/bin/mkdir -p /etc/kubernetes/manifests"
ExecStartPre=/usr/bin/mkdir -p /var/log/containers
ExecStartPre=-/usr/bin/rkt rm --uuid-file=/var/run/kubelet-pod.uuid
ExecStart=/usr/lib/coreos/kubelet-wrapper \\
  --kubeconfig=<__KUBECONFIG__> \\
  --network-plugin=<__NETWORK_PLUGIN__> \\
#  --cni-conf-dir=<__CNI_CONF__> \\
#  --cni-bin-dir=<__CNI_BIN__> \\
  --pod-cidr=<__POD_CIDR__> \\
  --container-runtime=docker \\
  --allow-privileged=true \\
  --pod-manifest-path=/etc/kubernetes/manifests \\
  --hostname-override=<__MASTER_IP__> \\
  --cluster_dns=<__DNS_SERVICE_IP__> \\
  --cluster_domain=cluster.local
ExecStop=-/usr/bin/rkt stop --uuid-file=/var/run/kubelet-pod.uuid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
`

  local _escaped_kubelet_conf=`escape_forward_slash "${KUBELET_CONF}"`
  local _escaped_calico=`escape_forward_slash "${_calico_dir}"`
  local _escaped_cni=`escape_forward_slash "${K8S_CNI_BIN}"`

  overwrite_content "${_content}" "${KUBELET_UNIT}" "sudo"

  replace_word_in_file "<__K8S_VERSION__>" "${K8S_VERSION}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__MASTER_IP__>" "${_master_ip}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__DNS_SERVICE_IP__>" "10.13.0.10" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__NETWORK_PLUGIN__>" "${K8S_NETWORK_PLUGIN}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__KUBECONFIG__>" "${_escaped_kubelet_conf}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__CNI_CONF__>" "${_escaped_calico}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__CNI_BIN__>" "${_escaped_cni}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__POD_CIDR__>" "${K8S_POD_CIDR}" "${KUBELET_UNIT}" "sudo"
}

function create_calico_kube_controllers_manifest() {
  local _etcd_host=$1

  local _content=`cat << EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: calico-kube-controllers
  namespace: kube-system
  labels:
    k8s-app: calico-kube-controllers
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      name: calico-kube-controllers
      namespace: kube-system
      labels:
        k8s-app: calico-kube-controllers
    spec:
      hostNetwork: true
      containers:
        - name: calico-kube-controllers
          image: quay.io/calico/kube-controllers:v2.0.1
          env:
            - name: ETCD_ENDPOINTS
              value: "http://${_etcd_host}:2379"
EOF`

  overwrite_content "${_content}" "${CALICO_KUBE_CONTROLLER_MANIFEST}" "sudo"
}

function create_kubelet_api_manifest() {
# The API server is where most of the magic happens. It is stateless by design and takes in API requests,
# processes them and stores the result in etcd if needed, and then returns the result of the request.
  local _master_host=$1 #ip
  local _etcd_host=$2 #ip

  local _content=`cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: quay.io/coreos/hyperkube:${K8S_VERSION}_coreos.0
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --secure-port=${KUBELET_API_SECURE_PORT}
    - --insecure-bind-address=0.0.0.0
    - --insecure-port=${KUBELET_API_INSECURE_PORT}
    - --etcd-servers=http://${_master_host}:2379
    - --allow-privileged=true
#    - --service-cluster-ip-range=10.13.0.0/24
    - --service-cluster-ip-range=192.168.201.0/24
    - --secure-port=443
    - --advertise-address=${_master_host}
    - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota
    - --tls-cert-file=${K8S_KEY_DIR}/${K8S_API_KEY}.pem
    - --tls-private-key-file=${K8S_KEY_DIR}/${K8S_API_KEY}-key.pem
    - --client-ca-file=${K8S_KEY_DIR}/${K8S_ROOT_KEY}.pem
    - --service-account-key-file=${K8S_KEY_DIR}/${K8S_API_KEY}-key.pem
    - --runtime-config=extensions/v1beta1=true,extensions/v1beta1/networkpolicies=true
    - --log-dir=${K8S_LOG_DIR}/kube_apiserver/
    ports:
    - containerPort: 443
      hostPort: 443
      name: https
    - containerPort: 8080
      hostPort: 8080
      name: local
    volumeMounts:
    - mountPath: ${K8S_KEY_DIR}
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: ${K8S_KEY_DIR}
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
EOF`

  overwrite_content "${_content}" "${KUBELET_API_MANIFEST}" "sudo"
}

function create_kubelet_pod_manifest() {
  # might not be required

  local _master_host=$1 #ip
  local _etcd_host=$2 #ip
  local _content=`cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-controller
spec:
  hostNetwork: true
  volumes:
    - name: "etc-kubernetes"
      hostPath:
        path: "/etc/kubernetes"
    - name: "ssl-certs"
      hostPath:
        path: "/usr/share/ca-certificates"
    - name: "var-run-kubernetes"
      hostPath:
        path: "/var/run/kubernetes"
    - name: "etcd-datadir"
      hostPath:
        path: "/var/lib/etcd"
    - name: "usr"
      hostPath:
        path: "/usr"
    - name: "lib64"
      hostPath:
        path: "/lib64"
  containers:
    - name: "etcd"
      image: "gcr.io/kuar/etcd:2.1.1"
      args:
        - "--data-dir=/var/lib/etcd"
        - "--advertise-client-urls=http://${_etcd_host}:2379"
        - "--listen-client-urls=http://${_etcd_host}:2379"
        - "--listen-peer-urls=http://${_etcd_host}:2380"
        - "--name=etcd"
      volumeMounts:
        - mountPath: /var/lib/etcd
          name: "etcd-datadir"
    - name: "kube-apiserver"
      image: "gcr.io/kuar/kube-apiserver:1.0.3"
      args:
        - "--allow-privileged=true"
        - "--etcd-servers=http://${_etcd_host}:2379"
        - "--insecure-bind-address=0.0.0.0"
        - "--service-cluster-ip-range=10.200.20.0/24"
        - "--v=2"
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: "etc-kubernetes"
        - mountPath: /var/run/kubernetes
          name: "var-run-kubernetes"
    - name: "kube-controller-manager"
      image: "gcr.io/kuar/kube-controller-manager:1.0.3"
      args:
        - "--master=http://${_master_host}:${KUBELET_API_INSECURE_PORT}"
        - "--v=2"
    - name: "kube-scheduler"
      image: "gcr.io/kuar/kube-scheduler:1.0.3"
      args:
        - "--master=http://${_master_host}:${KUBELET_API_INSECURE_PORT}"
        - "--v=2"
    - name: "kube-proxy"
      image: "gcr.io/kuar/kube-proxy:1.0.3"
      args:
        - "--master=http://${_master_host}:${KUBELET_API_INSECURE_PORT}"
        - "--v=2"
      securityContext:
        privileged: true
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: "etc-kubernetes"
        - mountPath: /etc/ssl/certs
          name: "ssl-certs"
        - mountPath: /usr
          name: "usr"
        - mountPath: /lib64
          name: "lib64"
EOF`

  overwrite_content "${_content}" "${KUBELET_POD_MANIFEST}" "sudo"
}

function create_kubelet_proxy_manifest() {
# The proxy is responsible for directing traffic destined for specific services and pods to the correct location.
# The proxy communicates with the API server periodically to keep up to date.
  local _master_host=$1
  local _content=`cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-proxy
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-proxy
    image: quay.io/coreos/hyperkube:${K8S_VERSION}_coreos.0
    command:
    - /hyperkube
    - proxy
    - --master=http://${_master_host}:${KUBELET_API_INSECURE_PORT}
    - --proxy-mode=iptables
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
EOF`

  overwrite_content "${_content}" "${KUBELET_PROXY_MANIFEST}" "sudo"
}

function create_kubelet_controller_manifest() {
# The controller manager is responsible for reconciling any required actions based on changes to Replication
# Controllers.

# For example, if you increased the replica count, the controller manager would generate a scale up event,
# which would cause a new Pod to get scheduled in the cluster. The controller manager communicates with the
# API to submit these events.

  local _master_host=$1
  local _content=`cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-controller-manager
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-controller-manager
    image: quay.io/coreos/hyperkube:${K8S_VERSION}_coreos.0
    command:
    - /hyperkube
    - controller-manager
    - --master=http://${_master_host}:${KUBELET_API_INSECURE_PORT}
    - --leader-elect=true
    - --service-account-private-key-file=${K8S_KEY_DIR}/${K8S_API_KEY}-key.pem
    - --root-ca-file=${K8S_KEY_DIR}/${K8S_ROOT_KEY}.pem
    livenessProbe:
      httpGet:
        host: ${_master_host}
        path: /healthz
        port: 10252
      initialDelaySeconds: 15
      timeoutSeconds: 1
    volumeMounts:
    - mountPath: ${K8S_KEY_DIR}
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: ${K8S_KEY_DIR}
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
EOF`

  overwrite_content "${_content}" "${KUBELET_CONTROLLER_MANIFEST}" "sudo"
}

function create_kubelet_scheduler_manifest() {
# The scheduler monitors the API for unscheduled pods, finds them a machine to run on, and communicates
# the decision back to the API.

  local _master=$1

  local _content=`cat << EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-scheduler
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-scheduler
    image: quay.io/coreos/hyperkube:${K8S_VERSION}_coreos.0
    command:
    - /hyperkube
    - scheduler
    - --master=http://${_master}:${KUBELET_API_INSECURE_PORT}
    - --leader-elect=true
    livenessProbe:
      httpGet:
        host: ${_master}
        path: /healthz
        port: 10251
      initialDelaySeconds: 15
      timeoutSeconds: 1
EOF`

  overwrite_content "${_content}" "${KUBELET_SCHEDULER_MANIFEST}" "sudo"
}

function create_kubelet_policy_controller_manifest() {
  # Implements the Kubernetes NetworkPolicy API by watching the Kubernetes API for Pod, Namespace,
  # and NetworkPolicy events and configuring Calico in response. It runs as a single pod managed by a ReplicaSet.
  local _etcd_host=$1

  local _content=`cat << EOF
apiVersion: extensions/v1beta1
kind: ReplicaSet
metadata:
  name: calico-policy-controller
  namespace: kube-system
  labels:
    k8s-app: calico-policy
spec:
  replicas: 1
  template:
    metadata:
      name: calico-policy-controller
      namespace: kube-system
      labels:
        k8s-app: calico-policy
    spec:
      hostNetwork: true
      containers:
        - name: calico-policy-controller
          # Make sure to pin this to your desired version.
          image: calico/kube-policy-controller:v0.3.0
          env:
            - name: ETCD_ENDPOINTS
              value: "http://${_etcd_host}:2379"
            - name: K8S_API
              value: "https://kubernetes.default:443"
            - name: CONFIGURE_ETC_HOSTS
              value: "true"
EOF`

  overwrite_content "${_content}" "${KUBELET_POLICY_CONTROLLER_MANIFEST}" "sudo"
}

function create_service_account_manifest() {
  local _name=$1

  local _content=`cat << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${_name}
  namespace: kube-system
EOF`

  overwrite_content "${_content}" "${K8S_MANIFEST_DIR}/service-${_name}.yaml" "sudo"
}

function create_rolebinding_manifest() {
  local _service=$1
  local _role=$2

  local _content=`cat << EOF
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: ${_service}
  labels:
    k8s-app: ${_service}
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${_role}
subjects:
- kind: ServiceAccount
  name: ${_service}
  namespace: kube-system
EOF`

  overwrite_content "${_content}" "${K8S_MANIFEST_DIR}/bind-${_service}-to-${_role}.yaml" "sudo"
}

function setup_kube_gui() {
  local _master=$1

  local _dashboard_download="https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

  kubectl create -f ${_dashboard_download}
  kubectl proxy --address="${_master}" --port=9090 --accept-hosts='^*$'&

  # http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy
}

function expose_deployment() {
  local _deployment=$1
  local _service=$2

  # loadbalancer/external IP is cloud provider feature, it will only work with GCP, AWS and Azure.
  kubectl expose deployment ${_deployment} --type=LoadBalancer --name=${_service}
}

function get_k8s_resources() {
  #pod
  #deployment
  #service
  #rolebindings.rbac.authorization.k8s.io
  #roles.rbac.authorization.k8s.io
  #serviceaccounts
  #secrets
  local _resource=$1

  run_and_validate_cmd "kubectl --namespace kube-system get ${_resource}"
}

function get_k8s_resource_info() {
  local _resource=$1

  run_and_validate_cmd "kubectl --namespace kube-system describe ${_resource}"
}

function delete_k8s_resource() {
  local _resource=$1
  local _name=$2

  run_and_validate_cmd "kubectl --namespace kube-system delete ${_resource} ${_name}"
}

function get_connection_state() {
  kubectl get cs
}

function get_k8s_secret() {
  local _secret=$1

  kubectl -n kube-system get secret
}

function get_k8s_pod_network_info() {
  local _pod=$1

  local _container_id=`kubectl -n kube-system get po ${_pod} -o jsonpath='{.status.containerStatuses[0].containerID}' | cut -c 10-21`
  log "${_container_id}" "[K8S][container_id]"

  local _pid=`docker inspect --format '{{ .State.Pid }}' ${_container_id}`
  log "${_pid}" "[K8S][_pid]"

  sudo nsenter -t ${_pid} -n ip addr
}

function test_k8s_deploy() {
  kubectl run my-nginx --image=nginx --replicas=2 --port=80
  kubectl delete deployment my-nginx
}

#----[ SETUP ]----#
#setup_calico_service_unit "$2"
#setup_cni_calico_plugin "$1"
#setup_cni_lo_plugin

#setup_tls_assets "$1"

#setup_kubecli "$1"
#setup_kubeadm

#create_kube_config
#set_kubeconfig_cluster "$1" "scratch"
#set_kubeconfig_context "dev-one"

#create_calico_kube_controllers_manifest "$2"
#create_kubelet_api_manifest "$1" "$2"
#create_kubelet_proxy_manifest "$1"
#create_kubelet_controller_manifest "$1"
#create_kubelet_scheduler_manifest "$1"
#create_kubelet_policy_controller_manifest "$2"

#setup_kubelet "$1"
#kubectl create -f /etc/kubernetes/manifests/calico-kube-controllers.yaml

#----[ ACCOUNT ]----#
#create_service_account_manifest "admin-user"
#create_rolebinding_manifest "admin-user" "cluster-admin"
#create_rolebinding_manifest "kubernetes-dashboard" "cluster-admin"
#service=`get_k8s_resources "secret" | grep admin-user | awk '{print $1}'`
#get_k8s_resource_info "secret ${service}"

#----[ DELETE ]----#
pod_name=`kubectl --namespace kube-system get pods | grep dashboard | cut -d' ' -f1`

delete_k8s_resource "deployment" "kubernetes-dashboard"
delete_k8s_resource "services" "kubernetes-dashboard"
delete_k8s_resource "secrets" "kubernetes-dashboard-certs"
delete_k8s_resource "serviceaccounts" "kubernetes-dashboard"
delete_k8s_resource "roles.rbac.authorization.k8s.io" "kubernetes-dashboard-minimal"
delete_k8s_resource "rolebindings.rbac.authorization.k8s.io" "kubernetes-dashboard-minimal"
delete_k8s_resource "pods" "${pod_name}"

#---[ DEBUG ]----#
#_pod=`get_k8s_resources "pods" | grep "kubernetes-dashboard" | awk '{print $1}'`
#get_k8s_pod_network_info "${_pod}"