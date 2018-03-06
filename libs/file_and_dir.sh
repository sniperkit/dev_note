. ./log.sh
. ./cmd.sh

function create_dir() {
  local dir=$1
  local sudo=${2:-}

  if [[ ! -d $dir ]]; then
    ${sudo} mkdir -p $dir && \
    log "${dir} ... ${FONT_GREEN} ok${FONT_NORMAL}" "[DIR][create]"
  else
    log "${dir} ... pass" "[DIR][create]"
  fi
}

function delete_dir_or_link() {
  local dir=$1

  if [[ -d $dir || -L $dir ]]; then
    rm -rf $dir && \
    log "${dir} ... ${FONT_GREEN} ok${FONT_NORMAL}" "[DIR][remove]"
  else
    log "${dir} ... pass" "[DIR][remove]"
  fi

}

function change_dir() {
  local dir=$1

  cd $dir && \
  log "$dir ... ${FONT_GREEN}ok${FONT_NORMAL}" "[DIR]" || \
  log "$dir ... ${FONT_RED}failed${FONT_NORMAL}" "[DIR]"
}

function copy_file_or_dir() {
  local src=$1
  local dst=$2
  local sudo=${3:-}

  [[ ! -d `dirname ${dst}` ]] && create_dir "`dirname ${dst}`"

  ${sudo} \cp -rf $src $dst && \
  log "${src} to ${dst} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[COPY]" || \
  log "${src} to ${dst} ... ${FONT_RED}failed${FONT_NORMAL}" "[COPY]"
}

function set_ownership() {
  local _user=$1
  local _group=$2
  local _path=$3
  local _sudo=${4:-}

#  chown -R ${user}:${group} ${path} && \
#  log "set ${user}:${group} ${path} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[OWNERSHIP]" || \
#  log "set ... ${FONT_RED}failed${FONT_NORMAL}" "[OWNERSHIP]"
  run_and_validate_cmd "${_sudo} chown -R ${_user}:${_group} ${_path}"
}

function set_permission() {
  local _permission=$1
  local _path=$2
  local _sudo=${3:-}

  run_and_validate_cmd "${_sudo} chmod ${_permission} ${_path}"
}

function overwrite_content() {
  local _content="$1"
  local _filepath=$2
#  local _cmd="echo \"${_content}\" > ${_filepath}"

#  run_and_validate_cmd "${_cmd}"
  echo "${_content}" > ${_filepath} && \
  log "${_filepath} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[FILE][update]" || \
  log "${_filepath} ... ${FONT_RED}failed${FONT_NORMAL}" "[FILE][update]"
}

function append_content() {
  local _content="$1"
  local _filepath=$2
  local _cmd="echo ${_content} >> ${_filepath}"

  run_and_validate_cmd "${_cmd}"
}

function search_file() {
  local dir=$1
  local filename=$2

  echo "find $dir -name \"$filename\""
  local result=`find $dir -name "$filename"`
  [[ $result ]] && \
  log "${FONT_GREEN}`realpath ${result}` ... ok${FONT_NORMAL}" "[FILE][search]" || \
  log "${FONT_RED}${filename}... failed${FONT_NORMAL}" "[FILE][search]"
}

function is_path() {
  local path=$1

  if [[ -f $path ]]; then
    log "${path} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[FILE][exist]"
    return 0
  else
    log "${path}... ${FONT_YELLOW}no${FONT_NORMAL}" "[FILE][exist]"
    return 1
  fi
}
