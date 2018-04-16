. ./cmd.sh
# https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs

function hash_password() {
  local f_out=${1:-}

  [[ ${f_out} ]] && \
  run_and_validate_cmd "sudo openssl passwd -1 > ${f_out}" || \
  run_and_validate_cmd "sudo openssl passwd -1"
}

function get_openssl_crt_info {
  local _path=$1

  openssl x509 -in ${_path} -text -noout
}

function set_openssl_crt_with_ip_san {
  # edit /etc/pki/tls/openssl.cnf subjectAltName = IP:10.0.0.10 under [ v3_ca ]
  openssl req -newkey rsa:2048 -nodes -keyout certs/domain.key -x509 -days 365 -out certs/domain.crt -subj '/C=TW/ST=Taipei/CN=172.27.11.167'
  openssl x509 -in ./certs/domain.crt -signkey ./certs/domain.key -x509toreq -out ./certs/domain.csr
}