. ./cmd.sh

function yum_dryrun() {
  local _dir=$1

  run_and_validate_cmd "yum -y --disablerepo=* localinstall ${_dir}/*.rpm --setopt tsflags=test"
}