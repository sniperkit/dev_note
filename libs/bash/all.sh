. ./configs.sh

# ==== FILE/DIR ==== #
function create_dir() {
  local dir=$1

  if [[ ! -d $dir ]]; then
    mkdir -p $dir && \
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

  [[ ! -d `dirname ${dst}` ]] && create_dir "`dirname ${dst}`"

  \cp -rf $src $dst && \
  log "${src} to ${dst} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[COPY]" || \
  log "${src} to ${dst} ... ${FONT_RED}failed${FONT_NORMAL}" "[COPY]"
}

function set_ownership() {
  local user=$1
  local group=$2
  local path=$3

  chown -R ${user}:${group} ${path} && \
  log "set ${user}:${group} ${path} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[OWNERSHIP]" || \
  log "set ... ${FONT_RED}failed${FONT_NORMAL}" "[OWNERSHIP]"
}

function set_permission() {
  local _permission=$1
  local _path=$2

  chmod ${_permission} ${_path} && \
  log "set ${_permission} ${_path} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PERMISSION]" || \
  log "set ${_permission} ${_path} ... ${FONT_RED}failed${FONT_NORMAL}" "[PERMISSIOM]"
}

function overwrite_content() {
  local _content="$1"
  local _filepath=$2
  local _cmd="echo ${_content} > ${_filepath}"

  run_and_validate_cmd "${_cmd}"
#  echo "${content}" > ${filepath} && \
#  log "${_filepath} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[FILE][update]" || \
#  log "${_filepath} ... ${FONT_RED}failed${FONT_NORMAL}" "[FILE][update]"
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

# ==== MOUNT ==== #
function remount_exec() {
  local dir=$1

  sudo mount $dir -o remount,exec && \
  log "${dir} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[MOUNT]" ||
  log "${dir} ... ${FONT_RED}fail${FONT_NORMAL}" "[MOUNT]"
}

# ==== WGET ==== #
function wget_url() {
  local url=$1
  local dst_dir=$2

  create_dir "${dst_dir}"
  pushd $dst_dir

  wget -N --no-check-certificate $url && \
  log "${url} to ${dst_dir} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[WGET][download]" || \
  log "${url} to ${dst_dir} ... ${FONT_RED}failed${FONT_NORMAL}" "[WGET][download]"

  popd
}

# ==== TAR ==== #
function untar_file() {
  local filename=$1
  local src_dir=$2
  local dst_dir=$3
  local opt=${4:-} # e.g "--strip 1"

  create_dir "${dst_dir}"

  tar -xvzf ${src_dir}/${filename} -C ${dst_dir}/ ${opt} && \
  log "${filename} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[UNTAR]" || \
  log "${filename} ... ${FONT_RED}failed${FONT_NORMAL}" "[UNTAR]"
}

# ==== LINK ==== #
function create_symbolic_link() {
  local src=$1
  local dst=$2

  delete_dir_or_link $dst

  [[ -f ${src} ]] && create_dir "`dirname ${dst}`"
#  [[ `dirname ${dst}` == '/' ]] && create_dir "${dst}"

  ln -s $src $dst && \
  log "${src}:${dst} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[LINK]" || \
  log "${src}:${dst} ... ${FONT_RED}failed${FONT_NORMAL}" "[LINK]"
}

# ==== GIT ==== #
function get_or_update_repo() {
  local git_url=$1
  local git_dir=$2

  if [[ `ls -A $git_dir 2>/dev/null` ]]; then
    pushd $git_dir && git pull && popd && \
    log "$git_dir ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][pull]" || \
    log "$git_dir ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][pull]"
  else
    git clone $git_url $git_dir && \
    log "$git_url ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][clone]" || \
    log "$git_url ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][clone]"
  fi
}


# ==== PYTHON ==== #
function is_python() {
  local py_version=${1:-}

  [[ $PATH =~ ":/usr/bin/python${py_version}" ]] && \
  return 0 || \
  return 1
}

function yum_setup_python3() {
  local version=$1

  IUS_REPO="https://centos7.iuscommunity.org/ius-release.rpm"

  yum_install "${IUS_REPO}"

  if [[ ${version} == '3.5' ]]; then
    yum_install "python35u"
    create_symbolic_link "/usr/bin/python3.5" "/usr/bin/python3"
    is_python "3" || export PATH=${PATH}:/usr/bin/python3
  fi
}

# ==== PIP ==== #
function is_pip() {
  local pip_version=${1:-}

  [[ $PATH =~ ":/usr/bin/pip${pip_version}" ]] && \
  return 0 || \
  return 1
}

function yum_setup_pip3() {
  local version=$1

  if [[ ${version} == '3.5' ]]; then
    yum_install "python35u-pip"
    create_symbolic_link "/usr/bin/pip3.5" "/usr/bin/pip3"
    is_pip "3" || export PATH=${PATH}:/usr/bin/pip3
  fi

}

function pip_install() {
  # curl https://bootstrap.pypa.io/get-pip.py | python3

  local version=$1
  local method=$2
  local source=$3

  if [[ $method =~ ^--file$ ]]; then
    pip${version} install -r $source && \
    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP][install]" || \
    log "$source .... ${FONT_RED}failed${FONT_NORMAL}" "[PIP][install]"
  elif [[ $method =~ ^--upgrade$ ]]; then
    pip${version} install --upgrade $source && \
    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP][upgrade]" || \
    log "$source ... ${FONT_RED}failed${FONT_NORMAL}" "[PIP][upgrade]"
  else
    pip${version} install $source && \
    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP][install]" || \
    log "$source ... ${FONT_RED}failed${FONT_NORMAL}" "[PIP][install]"
  fi
}

#function pip3_install() {
#  local method=$1
#  local source=$2
#
#  if [[ $method =~ ^--file$ ]]; then
#    pip3 install -r $source && \
#    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP3][install]" || \
#    log "$source .... ${FONT_RED}failed${FONT_NORMAL}" "[PIP][install]"
#  elif [[ $method =~ ^--upgrade$ ]]; then
#    pip3 install --upgrade $2 && \
#    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP3][upgrade]" || \
#    log "$source ... ${FONT_RED}failed${FONT_NORMAL}" "[PIP3][upgrade]"
#  else
#    pip3 install $source && \
#    log "$source ... ${FONT_GREEN}ok${FONT_NORMAL}" "[PIP3][install]" || \
#    log "$source ... ${FONT_RED}failed${FONT_NORMAL}" "[PIP3][install]"
#  fi
#}

# ==== VIRTUAL ENVIRONMENT === #
function install_virtualenv() {
  wget_url $VIRTUALENV_URL $SRC_HOME

  untar_file $VIRTUALENV_VERSION.tar.gz $SRC_HOME $SRC_HOME

  create_symbolic_link ${SRC_HOME}/${VIRTUALENV_VERSION} ${VIRTUALENV_SRC}

  change_dir $VIRTUALENV_SRC
  python ./setup.py install && \
  log " ... ${FONT_GREEN}ok${FONT_NORMAL}" "[VIRTUAL_ENV][install]" || \
  log " ... ${FONT_GREEN}failed${FONT_NORMAL}" "[VIRTUAL_ENV][install]"
}

function run_virtualenv() {
  local run_dir=$1
  local env=$2

  cd $run_dir && log $run_dir "[VENV][DIR]"

  if [[ ! -d venv ]]; then
    mkdir venv && \
    virtualenv --no-site-packages --prompt "($env) " venv && \
    log "venv ... ${FONT_GREEN}ok${FONT_NORMAL}" "[VENV][create]"
  else
    log "venv ... pass" "[VENV][create]"
  fi

  source venv/bin/activate && log "activate" "[VENV][source]"
}

# ==== CURL ==== #
function post_request() {
  local url=$1
  local payload=$2

  local cmd=`echo "curl -s -o /dev/null -w '%{http_code}' -XPOST $url --data-urlencode '${payload}'"`
  local status=`eval $cmd`
  if [[ ${status} == 200 ]]; then
    log "${FONT_GREEN}${status}${FONT_NORMAL}" "[POST]"
  else
    log "${FONT_RED}${status}${FONT_NORMAL}" "[POST]"
  fi
}

# ==== SOURCE ==== #
function source_file() {
  local filepath=$1

  source ${filepath} && \
  log "${filepath} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[SOURCE]" || \
  log "${filepath} ... ${FONT_RED}failed${FONT_NORMAL}" "[SOURCE]"
}

# ==== JAVA ==== #
function get_current_java_path() {
  local link_path=`ls -l /usr/bin/java | rev | cut -d" " -f1 | rev`
  if [[ ${link_path} =~ 'alternatives' ]]; then
    echo `/usr/sbin/alternatives --display java | grep 'link' | rev | cut -d" " -f1 | rev`
  else
    echo ${link_path} | sed 's/\/bin.*$//'
  fi
}

function set_java_home() {
  export JAVA_HOME=`get_current_java_path`
  log "`get_current_java_path`" "[JAVA][export]"
}

function add_java_external() {
  local src_path=$1
  local java_path=`get_current_java_path`
#  local ext_dir=${java_path%/bin*}/lib/ext/
  local ext_dir=${java_path}/jre/lib/ext/

  copy_file_or_dir "${src_path}" "${ext_dir}"
}

# ==== MAVEN ==== #
function setup_mvn() {
  [[ ! -f "${SRC_HOME}/${MAVEN_BINARY_TAR}" ]] && \
  wget_url "${MAVEN_DOWNLOAD}" "${SRC_HOME}"

  untar_file "${MAVEN_BINARY_TAR}" "${SRC_HOME}" "${MAVEN_HOME}"

  create_symbolic_link "$MAVEN_HOME/apache-maven-${MAVEN_VERSION}" "$MAVEN_HOME/maven"

  overwrite_content "${MAVEN_ENV_INPUT}" "${MAVEN_ENV}"

  source_file "$MAVEN_ENV"
}

#function mvn_compile() {
function mvn_build_and_verify() {
  local dst_dir=$1

  pushd ${dst_dir}

  mvn -T ${MAVEN_THREAD} --batch-mode clean verify && \
  log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[MVN][BUILD_VERIFY]" || \
  log "... ${FONT_RED}failed${FONT_NORMAL}" "[MVN][BUILD_VERIFY]"

  popd
}

function mvn_assemble() {
  local dst_dir=$1

  pushd ${dst_dir}

  mvn -T ${MAVEN_THREAD} clean compile assembly:single && \
  log "... ${FONT_GREEN}ok${FONT_NORMAL}" "[MVN][ASSEMBLE]" || \
  log "... ${FONT_RED}failed${FONT_NORMAL}" "[MVN][ASSEMBLE]"

  popd
}

# ==== INFLUXDB ==== #
function show_influxdb_users() {
  curl -XPOST "http://localhost:8086/query?pretty=true" --data-urlencode "q=SHOW USERS"
}

function create_influxdb_user() {
  local db_user=$1
  local db_pass=$2

  query_cmd="CREATE USER ${db_user} WITH PASSWORD '${db_pass}' WITH ALL PRIVILEGES"

  curl "http://localhost:8086/query" --data-urlencode "q=${query_cmd}" && \
  log "${db_user}:${db_pass} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[INFLUXDB][create]" || \
  log "${db_user}:${db_pass} ... ${FONT_RED}failed${FONT_NORMAL}" "[INFLUXDB][create]"
}

function show_influxdb_databases() {
  curl -XPOST "http://localhost:8086/query?pretty=true" --data-urlencode "q=SHOW DATABASES"
}

function create_influxdb_database() {
  local db_name=$1

  post_request "http://localhost:8086/query" "q=CREATE DATABASE \"${db_name}\"" && \
  log "${db_name} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[INFLUXDB][create]" || \
  log "${db_name} ... ${FONT_RED}failed${FONT_NORMAL}" "[INFLUXDB][create]"
}

# ==== ELASTICSEARCH ==== #
function get_elasticserach_info() {
  local e_host=$1
  local e_port=$2

  curl -XGET "http://${e_host}:${e_port}"
}

# ==== LIGHTTPD ==== #
function set_lighttpd_port() {
  local new_port=$1

  sed -E -i "s/^(server.port.*=)(.*)$/\1 ${new_port}/" "${LIGHTTPD_CONF}" && \
  log "port: ${new_port} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[LIGHTTPD][replace]" || \
  log "port: ${new_port} ... ${FONT_RED}failed${FONT_NORMAL}" "[LIGHTTPD][replace]"
}

# ==== SERVICE ==== #
function do_service() {
  local _service=$1
  local _action=$2

  systemctl $_action ${_service} && \
  log "${_action}... ${FONT_GREEN}ok${FONT_NORMAL}" "[DOCKER][${_service}]" || \
  log "${_action}... ${FONT_RED}failed${FONT_NORMAL}" "[DOCKER][${_service}]"
}

# ==== DOCKER ==== #
DOCKER_DEFAULT_STORAGE_DIR='/var/lib/docker'
DOCKER_STORAGE_DIR='/opt/docker_volume'
DOCKER_SERVICE_DIR='/etc/systemd/system/docker.service.d'
DOCKER_SERVICE_FILE='docker.conf'
DOCKER_SERVICE_FILE_IN=`cat << EOL
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --graph=${DOCKER_STORAGE_DIR} --storage-driver=devicemapper
EOL
`

function set_docker_storage() {
  # https://sanenthusiast.com/change-default-image-container-location-docker/
  do_service 'docker' 'stop'
  create_dir "${DOCKER_SERVICE_DIR}"
  overwrite_content "${DOCKER_SERVICE_FILE_IN}" "${DOCKER_SERVICE_DIR}/${DOCKER_SERVICE_FILE}"

#  copy_file_or_dir "${DOCKER_DEFAULT_STORAGE_DIR}" "${DOCKER_STORAGE_DIR}"
#  create_symbolic_link "${DOCKER_STORAGE_DIR}" "${DOCKER_DEFAULT_STORAGE_DIR}"

  systemctl daemon-reload
  do_service 'docker' 'start'
}
