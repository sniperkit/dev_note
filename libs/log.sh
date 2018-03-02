FONT_BOLD='\e[1m'
FONT_NORMAL='\e[0m'
FONT_RED='\e[31m'
FONT_GREEN='\e[32m'
FONT_YELLOW='\e[33m'

function log() {
  local log=${1:-}
  local tag=${2:-}

  [[ $3 != 'ts=0' ]] && printf "$FONT_BOLD`date +"%T"` --- $FONT_NORMAL"
  [[ $tag ]] && printf "$FONT_BOLD$tag $FONT_NORMAL"
  [[ $log ]] && printf "$log\n"
}