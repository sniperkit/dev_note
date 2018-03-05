#!/usr/bin/env bash
. ./cmd.sh
. ./file_and_dir.sh
. ./sed.sh

TMP_DIR=`eval echo ~$USER`
K8S_ROOT="/etc/kubernetes"

K8S_TMP_KEY_DIR="${TMP_DIR}/kube-ssl"
K8S_KEY_DIR="${K8S_ROOT}/ssl"

K8S_ROOT_KEY="ca"

K8S_API_KEY_CONF="openssl.cnf"
K8S_API_KEY="apiserver"

K8S_WORKER_KEY_CONF="worker-openssl.cnf"
#K8S_WORKER_KEY="<__FQDN__>"

K8SCTL="kubectl"
K8SCTL_DOWNLOAD="https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/${K8SCTL}"
K8SCTL_RUN="/opt/bin/${K8SCTL}"

KUBELET_UNIT="kubelet.service"
KUBELET_RUN="/etc/systemd/system/${KUBELET_UNIT}"

K8S_API_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
K8S_POD_MANIFEST="/etc/kubernetes/manifests/kubernetes.yaml"
K8S_PROXY_MANIFEST="/etc/kubernetes/manifests/kube-proxy.yaml"
K8S_CONTROLLER_MANIFEST="/etc/kubernetes/manifests/kube-controller-manager.yaml"
K8S_SCHEDULER_MANIFEST="/etc/kubernetes/manifests/kube-scheduler.yaml"

function create_root_keys() {
  local _key=${1:-$K8S_ROOT_KEY}

  sudo openssl genrsa -out ${_key}-key.pem 2048
  sudo openssl req -x509 -new -nodes -key ${_key}-key.pem -days 10000 -out ${_key}.pem -subj "/CN=kube-ca"
}

function create_api_server_keys() {
  local _master=$1 #ip
  local _key_conf=${2:-$K8S_API_KEY_CONF}
  local _apikey=${3:-$K8S_API_KEY}
  local _rootkey=${4:-$K8S_ROOT_KEY}
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

  overwrite_content "${_content}" "${_key_conf}"
  replace_word_in_file "<__MASTER_PUBLIC_IP__>" "${_master}" "${_key_conf}"

  sudo openssl genrsa -out ${_apikey}-key.pem 2048
  sudo openssl req -new -key ${_apikey}-key.pem -out ${_apikey}.csr -subj "/CN=kube-apiserver" -config ${_key_conf}
  sudo openssl x509 -req -in ${_apikey}.csr -CA ${_rootkey}.pem -CAkey ${_rootkey}-key.pem -CAcreateserial -out ${_apikey}.pem -days 365 -extensions v3_req -extfile ${_key_conf}
}

function create_worker_keys() {
  local _worker_ip=$1 #ip
  local _worker_fqdn=${2:-$_worker_ip}
  local _key_conf=${3:-$K8S_WORKER_KEY_CONF}
#  local _apikey=${3:-$K8S_API_KEY}
  local _rootkey=${4:-$K8S_ROOT_KEY}
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
IP.1 = $ENV::WORKER_IP
EOF
`

  overwrite_content "${_content}" "${_key_conf}"
#  replace_word_in_file "<__WORKER_IP__>" "${_worker_ip}" "${_key_conf}"

  openssl genrsa -out ${_worker_fqdn}-worker-key.pem 2048

  WORKER_IP=${_worker_ip} \
  openssl req -new -key ${_worker_fqdn}-worker-key.pem -out ${_worker_fqdn}-worker.csr -subj "/CN=${_worker_fqdn}" -config ${_key_conf}

  WORKER_IP=${_worker_ip} \
  openssl x509 -req -in ${_worker_fqdn}-worker.csr -CA ${_rootkey}.pem -CAkey ${_rootkey}-key.pem -CAcreateserial -out ${_worker_fqdn}-worker.pem -days 365 -extensions v3_req -extfile ${_key_conf}
}

function setup_tls_assets() {
  local _master=$1
  local _tls_tmp_dir=${2:-$K8S_TMP_KEY_DIR}
  local _tls_dir=${2:-$K8S_KEY_DIR}

  create_dir "$_tls_tmp_dir"
  create_dir "$_tls_dir"

  pushd ${_tls_tmp_dir}

  create_root_keys
  create_api_server_keys ${_master}
#  create_worker_keys ${_worker}

  sudo cp ${_tls_tmp_dir}/*.pem ${_tls_dir}/
  set_permission "600" "${_tls_dir}/*-key.pem" "sudo"
  set_ownership "root" "root" "${_tls_dir}/*-key.pem" "sudo"
  popd
}

function setup_k8scli() {
  local _download=${1:-$K8SCTL_DOWNLOAD}

  pushd ~
  run_and_validate_cmd "curl ${_download} -o ${K8SCTL}"
  run_and_validate_cmd "sudo chmod +x ${K8SCTL}"
  run_and_validate_cmd "sudo mkdir -p `dirname ${K8SCTL_RUN}`"
  run_and_validate_cmd "sudo mv ${K8SCTL} ${K8SCTL_RUN}"
  popd
}

function setup_kubelet_service() {
  local _master_ip=$1
  local _service=${2:-$KUBELET_RUN}
  local _service_file=`basename ${_service}`
  local _content=`cat << 'EOF'
[Service]
Environment=KUBELET_VERSION=v1.3.5_coreos.0
ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
ExecStart=/usr/lib/coreos/kubelet-wrapper \\\

  --api-servers=http://127.0.0.1:8080 \\\

  --register-schedulable=false \\\

  --allow-privileged=true \\\

  --config=/etc/kubernetes/manifests \\\

  --hostname-override=<__MASTER_IP__> \\\

  --cluster-dns=10.13.0.10 \\\

  --cluster-domain=cluster.local
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
`

  pushd ~
  overwrite_content "${_content}" "${_service_file}"
  replace_word_in_file "<__MASTER_IP__>" "${_master_ip}" "${_service_file}"
  run_and_validate_cmd "sudo mv -f ${_service_file} /etc/systemd/system/"
  popd
}

function create_k8sapi_manifest() {
  local _master_ip=$1
  local _manifest=${2:-$K8S_API_MANIFEST}
  local _manifest_file=`basename ${_manifest}`

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
    image: quay.io/coreos/hyperkube:v1.3.5_coreos.0
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --etcd-servers=http://<__master_ip__>:2379
    - --allow-privileged=true
    - --service-cluster-ip-range=10.13.0.0/24
    - --secure-port=443
    - --advertise-address=<__master_ip__>
    - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota
    - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
    - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --client-ca-file=/etc/kubernetes/ssl/ca.pem
    - --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --runtime-config=extensions/v1beta1=true,extensions/v1beta1/networkpolicies=true
    ports:
    - containerPort: 443
      hostPort: 443
      name: https
    - containerPort: 8080
      hostPort: 8080
      name: local
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
EOF`

  pushd ~
  overwrite_content "${_content}" "${_manifest_file}"
  replace_word_in_file "<__master_ip__>" "${_master_ip}" "${_manifest_file}"
  run_and_validate_cmd "sudo mv -f ${_manifest_file} ${_manifest}"
  popd
}

function create_k8spod_manifest() {
  local _manifest=${1:-$K8S_POD_MANIFEST}
  local _manifest_file=`basename ${_manifest}`

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
      image: "b.gcr.io/kuar/etcd:2.1.1"
      args:
        - "--data-dir=/var/lib/etcd"
        - "--advertise-client-urls=http://127.0.0.1:2379"
        - "--listen-client-urls=http://127.0.0.1:2379"
        - "--listen-peer-urls=http://127.0.0.1:2380"
        - "--name=etcd"
      volumeMounts:
        - mountPath: /var/lib/etcd
          name: "etcd-datadir"
    - name: "kube-apiserver"
      image: "b.gcr.io/kuar/kube-apiserver:1.0.3"
      args:
        - "--allow-privileged=true"
        - "--etcd-servers=http://127.0.0.1:2379"
        - "--insecure-bind-address=0.0.0.0"
        - "--service-cluster-ip-range=10.200.20.0/24"
        - "--v=2"
      volumeMounts:
        - mountPath: /etc/kubernetes
          name: "etc-kubernetes"
        - mountPath: /var/run/kubernetes
          name: "var-run-kubernetes"
    - name: "kube-controller-manager"
      image: "b.gcr.io/kuar/kube-controller-manager:1.0.3"
      args:
        - "--master=http://127.0.0.1:8080"
        - "--v=2"
    - name: "kube-scheduler"
      image: "b.gcr.io/kuar/kube-scheduler:1.0.3"
      args:
        - "--master=http://127.0.0.1:8080"
        - "--v=2"
    - name: "kube-proxy"
      image: "b.gcr.io/kuar/kube-proxy:1.0.3"
      args:
        - "--master=http://127.0.0.1:8080"
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

  pushd ~
  overwrite_content "${_content}" "${_manifest_file}"
#  replace_word_in_file "<__master_ip__>" "${_master_ip}" "${_manifest_file}"
  run_and_validate_cmd "sudo mv -f ${_manifest_file} ${_manifest}"
  popd
}

function create_k8s_proxy() {
  local _proxy=${1:-$K8S_PROXY_MANIFEST}
  local _proxy_file=`basename ${_proxy}`

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
    image: quay.io/coreos/hyperkube:v1.3.5_coreos.0
    command:
    - /hyperkube
    - proxy
    - --master=http://127.0.0.1:8080
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

  pushd ~
  overwrite_content "${_content}" "${_proxy_file}"
#  replace_word_in_file "<__master_ip__>" "${_master_ip}" "${_proxy_file}"
  run_and_validate_cmd "sudo mv -f ${_proxy_file} ${_proxy}"
  popd
}

function create_k8s_controller() {
  local _controller=${1:-$K8S_CONTROLLER_MANIFEST}
  local _controller_file=`basename ${_controller}`

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
    image: quay.io/coreos/hyperkube:v1.3.5_coreos.0
    command:
    - /hyperkube
    - controller-manager
    - --master=http://127.0.0.1:8080
    - --leader-elect=true
    - --service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --root-ca-file=/etc/kubernetes/ssl/ca.pem
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
      initialDelaySeconds: 15
      timeoutSeconds: 1
    volumeMounts:
    - mountPath: /etc/kubernetes/ssl
      name: ssl-certs-kubernetes
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/ssl
    name: ssl-certs-kubernetes
  - hostPath:
      path: /usr/share/ca-certificates
    name: ssl-certs-host
EOF`

  pushd ~
  overwrite_content "${_content}" "${_controller_file}"
#  replace_word_in_file "<__master_ip__>" "${_master_ip}" "${_controller_file}"
  run_and_validate_cmd "sudo mv -f ${_controller_file} ${_controller}"
  popd
}

function create_k8s_scheduler() {
  local _scheduler=${1:-$K8S_SCHEDULER_MANIFEST}
  local _scheduler_file=`basename ${_scheduler}`

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
    image: quay.io/coreos/hyperkube:v1.3.5_coreos.0
    command:
    - /hyperkube
    - scheduler
    - --master=http://127.0.0.1:8080
    - --leader-elect=true
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10251
      initialDelaySeconds: 15
      timeoutSeconds: 1
EOF`

  pushd ~
  overwrite_content "${_content}" "${_scheduler_file}"
#  replace_word_in_file "<__master_ip__>" "${_master_ip}" "${_scheduler_file}"
  run_and_validate_cmd "sudo mv -f ${_scheduler_file} ${_scheduler}"
  popd
}