. ./log.sh
. ./cmd.sh
. ./hash.sh

function create_dir() {
  local dir=$1
  local sudo=${2:-}

  if [[ ! -d $dir ]]; then
    ${sudo} mkdir -p $dir && \
    log "${dir} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[DIR][create]"
  else
    log "${dir} ... ${FONT_YELLOW}pass${FONT_NORMAL}" "[DIR][create]"
  fi
}

function delete_pathlink() {
  local _path=$1

  if [[ -f ${_path} || -d ${_path}  || -L ${_path}  ]]; then
    rm -rf ${_path}  && \
    log "${_path} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[DIR][remove]"
  else
    log "${_path} ... ${FONT_YELLOW}pass${FONT_NORMAL}" "[DIR][remove]"
  fi

}

function change_dir {
  local _dest_dir=$1

  cd ${_dest_dir} && \
  ( log "${_dest_dir} ... ${FONT_GREEN}OK${FONT_NORMAL}" "[DIR][change]" && return 0 ) || \
  ( log "${_dest_dir} ... ${FONT_RED}ERROR${FONT_NORMAL}" "[DIR][change]" && return 1 )
}

function copy_file_or_dir() {
  local src=$1
  local dst=$2
  local sudo=${3:-}

  [[ ! -d `dirname ${dst}` ]] && create_dir "`dirname ${dst}`"

  compare_item_hash "$src" "$dst" && \
  ( \
  ${sudo} \cp -rf $src $dst && \
  log "${src} to ${dst} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[COPY]" || \
  log "${src} to ${dst} ... ${FONT_RED}failed${FONT_NORMAL}" "[COPY]" \
  )
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
  local _sudo=${3:-}
  local _tmp_dir=`eval echo ~$USER`
#  local _cmd="echo \"${_content}\" > ${_filepath}"

  echo "${_tmp_dir}/`basename ${_filepath}`"
  echo "${_filepath}"

#  run_and_validate_cmd "${_cmd}"
  if [[ ${_sudo} ]]; then
    overwrite_content "${_content}" "${_tmp_dir}/`basename ${_filepath}`"
    create_dir "`dirname ${_filepath}`" "sudo"
    copy_file_or_dir "${_tmp_dir}/`basename ${_filepath}`" "${_filepath}" "sudo"
    delete_pathlink "${_tmp_dir}/`basename ${_filepath}`"
  else
    echo "${_content}" > ${_filepath} && \
    log "${_filepath} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[FILE][update]" || \
    log "${_filepath} ... ${FONT_RED}failed${FONT_NORMAL}" "[FILE][update]"
  fi
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

function sort_file() {
  local _file=$1
  local _file_type=$2

  if [[ $_file_type = 'json' ]]; then
    cat ${_file} | python -m json.tool > ${_file}.sorted && \
    log "${_file}.sorted ... ${FONT_GREEN}DONE${FONT_NORMAL}" "[FILE][sort_json]" || \
    log "${_file}.sorted ... ${FONT_RED}ERROR${FONT_NORMAL}" "[FILE][sort_json]"
  fi
}
