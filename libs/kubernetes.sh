#!/usr/bin/env bash
. ./cmd.sh
. ./file_and_dir.sh
. ./sed.sh
. ./log.sh

# reference:
# https://hk.saowen.com/a/4bcd4ff5fbdb05930119ce3c0f2d5c7b8de7200553ab5d1f85492585ee3159db
# https://wiki.mikejung.biz/Kubernetes
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

TMP_DIR=`eval echo ~$USER`

K8S_VERSION="v1.9.3_coreos.0"
K8S_DNS_SERVICE_IP="8.8.8.8"
K8S_NETWORK_PLUGIN="cni"

K8S_TMP_KEY_DIR="${TMP_DIR}/kube-ssl"
K8S_KEY_DIR="/etc/kubernetes/ssl"
K8S_LOG_DIR="/var/log/kubernetes"

K8S_ROOT_KEY="ca"

K8S_API_KEY_CONF="openssl.cnf"
K8S_API_KEY="apiserver"

K8S_WORKER_KEY_CONF="worker-openssl.cnf"
#K8S_WORKER_KEY="<__FQDN__>"

K8S_CNI_CALICO="/etc/kubernetes/cni/net.d/10-calico.conf"

KUBECTL_DOWNLOAD="https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/kubectl"
KUBECTL_RUN="/opt/bin/kubectl"

KUBELET_UNIT="/etc/systemd/system/kubelet.service"

KUBELET_CONF="/etc/kubernetes/kubelet.kubeconfig"

KUBELET_API_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
KUBELET_POD_MANIFEST="/etc/kubernetes/manifests/kubernetes.yaml"
KUBELET_PROXY_MANIFEST="/etc/kubernetes/manifests/kube-proxy.yaml"
KUBELET_CONTROLLER_MANIFEST="/etc/kubernetes/manifests/kube-controller-manager.yaml"
KUBELET_SCHEDULER_MANIFEST="/etc/kubernetes/manifests/kube-scheduler.yaml"

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

  overwrite_content "${KUBELET_CONF}" "sudo"
}

function set_kubeconfig_cluster() {
  local _master=$1
  local _cluster=$2
  local _option=${3:-}

  if [ "${_option}" = "insecure" ]; then
    sudo kubectl config --kubeconfig=${KUBELET_CONF} set-cluster ${_cluster} \
    --server=https://${_master}:${KUBELET_API_SECURE_PORT} \
    --insecure-skip-tls-verify && \
    log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[KUBECTL][insecure][set-cluster]" ||
    log "... ${FONT_RED}failed${FONT_NORMAL}" "[KUBECTL][insecure][set-cluster]"
  else
    sudo kubectl config --kubeconfig=${KUBELET_CONF} set-cluster ${_cluster} \
    --server=https://${_master}:${KUBELET_API_SECURE_PORT} \
    --certificate-authority=${K8S_KEY_DIR}/${K8S_ROOT_KEY.pem} && \
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
  create_dir "${K8S_KEY_DIR}"

  pushd ${K8S_TMP_KEY_DIR}}

  create_root_keys
  create_api_server_keys ${_master}
#  create_worker_keys ${_worker}

  sudo cp ${K8S_TMP_KEY_DIR}}/*.pem ${K8S_KEY_DIR}/
  set_permission "600" "${K8S_KEY_DIR}/*-key.pem" "sudo"
  set_ownership "root" "root" "${K8S_KEY_DIR}/*-key.pem" "sudo"

  popd
}

function setup_cni_calico_network() {
  local _etcd_host=$1 #ip

  local _content=`cat << EOF
{
    "name": "calico-k8s-network",
    "type": "calico",
    "etcd_endpoints": "http://${_etcd_host}:2379",
    "log_level": "info",
    "ipam": {
        "type": "calico-ipam"
    },
    "policy": {
        "type": "k8s"
    }
}
EOF`

  overwrite_content "${_content}" "${K8S_CNI_CALICO}" "sudo"
}

function setup_cni_flannel_network() {
  local _master=$1 #ip
  local _flannel_config="/etc/flannel/options.env"
  local _flannel_config_content=`cat << EOF
FLANNELD_IFACE=${_master}
FLANNELD_ETCD_ENDPOINTS=http://${_master}:2379
EOF
`
  local _flannel_unit="/etc/systemd/system/flanneld.service.d"
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

function setup_kubeadm() {
#  the command to bootstrap the cluster.
  :
}

function setup_kubecli() {
#  the command line util to talk to your cluster.

  local _master=$1

  pushd ~
  run_and_validate_cmd "curl ${KUBECTL_DOWNLOAD} -o ${KUBECTL}"
  run_and_validate_cmd "sudo chmod +x ${KUBECTL}"
  run_and_validate_cmd "sudo mkdir -p `dirname ${KUBECTL_RUN}`"
  run_and_validate_cmd "sudo mv ${KUBECTL} ${KUBECTL_RUN}"
  popd

  export KUBERNETES_MASTER=http://${_master}:${KUBELET_API_INSECURE_PORT}
}

function setup_kubelet() {
#  the component that runs on all of the machines in your cluster and does things like starting pods and containers.

  local _master_ip=$1
  local _cni_dir=`dirname ${K8S_CNI_CALICO}`
  local _content=`cat << "EOF"
[Service]
Environment=KUBELET_IMAGE_TAG=<__K8S_VERSION__>
Environment="RKT_RUN_ARGS=--uuid-file-save=/var/run/kubelet-pod.uuid \\
  --volume var-log,kind=host,source=/var/log \\
  --mount volume=var-log,target=/var/log \\
  --volume dns,kind=host,source=/etc/resolv.conf \\
  --mount volume=dns,target=/etc/resolv.conf" \\
ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
ExecStartPre=/usr/bin/mkdir -p /var/log/containers
ExecStartPre=-/usr/bin/rkt rm --uuid-file=/var/run/kubelet-pod.uuid
ExecStart=/usr/lib/coreos/kubelet-wrapper \\
  --kubeconfig=<__KUBECONFIG__> \\
  --cni-conf-dir=<__CNI_DIR__> \\
  --network-plugin=<__NETWORK_PLUGIN__> \\
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
  local _escaped_cni=`escape_forward_slash "${_cni_dir}"`

  overwrite_content "${_content}" "${KUBELET_UNIT}" "sudo"

  replace_word_in_file "<__K8S_VERSION__>" "${K8S_VERSION}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__MASTER_IP__>" "${_master_ip}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__DNS_SERVICE_IP__>" "${_master_ip}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__NETWORK_PLUGIN__>" "${K8S_NETWORK_PLUGIN}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__KUBECONFIG__>" "${_escaped_kubelet_conf}" "${KUBELET_UNIT}" "sudo"
  replace_word_in_file "<__CNI_DIR__>" "${_escaped_cni}" "${KUBELET_UNIT}" "sudo"
}

function create_kubelet_api_manifest() {
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
    image: quay.io/coreos/hyperkube:${K8S_VERSION}
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --secure-port=${KUBELET_API_SECURE_PORT}
    - --insecure-bind-address=0.0.0.0
    - --insecure-port=${KUBELET_API_INSECURE_PORT}
    - --etcd-servers=http://${_etcd_host}:2379
    - --allow-privileged=true
    - --service-cluster-ip-range=10.13.0.0/24
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
    image: quay.io/coreos/hyperkube:${K8S_VERSION}
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

  overwrite_content "${_content}" "${KUBELET_PROXY_MANIFEST}"
}

function create_kubelet_controller_manifest() {
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
    image: quay.io/coreos/hyperkube:${K8S_VERSION}
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

  overwrite_content "${_content}" "${KUBELET_CONTROLLER_MANIFEST}"
}

function create_kubelet_scheduler_manifest() {
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
    image: quay.io/coreos/hyperkube:${K8S_VERSION}
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


#setup_cni_calico_network "$1"
#set_kubeconfig_cluster "$1" "scratch"
#set_kubeconfig_context "dev-one"
#create_kubelet_api_manifest "$1" "$2"
#create_kubelet_pod_manifest "$1" "$2"
#create_kubelet_proxy_manifest "$1"
#create_kubelet_controller_manifest "$1"
#create_kubelet_scheduler_manifest "$1"
#setup_kubelet "$1"