. ./log.sh

function curl_request() {
  local _cmd=$1
  echo $_cmd

  local status=`eval ${_cmd}`
  if [[ ${status} == 200 ]]; then
    log "... ${FONT_GREEN}${status}${FONT_NORMAL}" "[CURL]"
  else
    log "... ${FONT_RED}${status}${FONT_NORMAL}" "[CURL]"
  fi
}