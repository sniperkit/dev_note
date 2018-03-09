. cmd.sh

function yum_dryrun() {
  local _dir=$1

  run_and_validate_cmd "yum -y --disablerepo=* localinstall ${_dir}/*.rpm --setopt tsflags=test"
}

function yum_install() {
  local pkg=$1

  yum install $pkg && \
  log "$pkg ... ${FONT_GREEN}ok${FONT_NORMAL}" "[YUM][install]" || \
  log "$pkg ... ${FONT_RED}failed${FONT_NORMAL}" "[YUM][install]"
}