. ./log.sh

function replace_word_in_file() {
  local _replace=$1
  local _with=$2
  local _file=$3

  sed -E -i "s/${_replace}/${_with}/" ${_file} && \
  log "${FONT_GREEN} ... success${FONT_NORMAL}" "[SED][replace]" || \
  log "${FONT_RED} ... failed${FONT_NORMAL}" "[SED][replace]"
}