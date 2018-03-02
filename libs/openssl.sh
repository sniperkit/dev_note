. ./cmd.sh

sudo openssl passwd -1 > cloud-config-file

function hash_password() {
  local f_out=${1:-}

  [[ ${f_out} ]] && \
  run_and_validate_cmd "sudo openssl passwd -1 > ${f_out}" || \
  run_and_validate_cmd "sudo openssl passwd -1"
}