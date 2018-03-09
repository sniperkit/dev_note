. log.sh

function run_and_validate_cmd() {
  local _cmd="$1"

  log "${_cmd}" "[SHELL_CMD]"

  $_cmd && \
  log "${FONT_GREEN} ... success${FONT_NORMAL}" "[SHELL_CMD][exec]" || \
  log "${FONT_RED} ... failed${FONT_NORMAL}" "[SHELL_CMD][exec]"
}