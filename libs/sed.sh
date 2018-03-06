. ./log.sh

function replace_word_in_file() {
  local _replace=$1
  local _with=$2
  local _file=$3
  local _sudo=${4:-}

  echo "sed -E -i \"s/${_replace}/${_with}/\" ${_file}"
  ${_sudo} sed -E -i "s/${_replace}/${_with}/" ${_file} && \
  log "${FONT_GREEN} ... success${FONT_NORMAL}" "[SED][replace]" || \
  log "${FONT_RED} ... failed${FONT_NORMAL}" "[SED][replace]"
}

function escape_forward_slash() {
  local _input=$1

  echo ${_input} | sed 's/\//\\\//g' && return 0 || return 1
}