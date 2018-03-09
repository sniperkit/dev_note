. log.sh

function compare_item_hash() {
  local _item1=`md5sum $1`
  local _item2=`md5sum $2`

  if [ "${_item1}" = "${_item2}" ]; then
    log "$1 vs $2 ... ${FONT_YELLOW}identical${FONT_NORMAL}" "[CHECK][items]" && \
    return 1
  else
    log "$1 vs $2 ... ${FONT_YELLOW}not identical${FONT_NORMAL}" "[CHECK][items]" && \
    return 0
  fi
}
