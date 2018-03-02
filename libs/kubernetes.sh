. ./cmd.sh
. ./file_and_dir.sh

K8SCTL="kubectl"
K8SCTL_DOWNLOAD="https://storage.googleapis.com/kubernetes-release/release/v1.8.4/bin/linux/amd64/${K8SCTL}"

function setup_k8scli() {
  local _download=${1:-$K8SCTL_DOWNLOAD}

  run_and_validate_cmd "curl -O ${_download}"
  run_and_validate_cmd "chmod -x ${K8SCTL}"
  run_and_validate_cmd "sudo mv ${K8SCTL} /usr/local/bin/${K8SCTL}"
}