. cmd.sh

function rpm_dryrun() {
  local _dir=${1:-}

  run_and_validate_cmd "rpm -i --replacepkgs --test ${_dir}/*.rpm"
}