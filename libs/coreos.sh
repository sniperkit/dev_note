. ./cmd.sh

function install_coreos() {
  local _conf=$1
  local _extension=`echo ${_conf} | cut -d'.' -f2`

  [[ ${_extension} == 'json' ]] && \
  run_and_validate_cmd "sudo coreos-install -d /dev/sda -C stable -i ${_conf}"

  [[ ${_extension} == 'yaml' ]] && \
  run_and_validate_cmd "sudo coreos-install -d /dev/sda -C stable -c ${_conf}"

  # journalctl -t ignition
}

function get_discovery_token() {
  curl https://discovery.etcd.io/new | rev | cut -d'/' -f1 | rev
}