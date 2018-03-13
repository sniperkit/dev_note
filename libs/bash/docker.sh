. ./log.sh
. ./git.sh
. ./file_and_dir.sh

function get_docker_info() {
  docker info
}

function docker_stop_all_containers() {
  for container in `docker ps | tail -n +2 | awk '{print $1}'`
  do
    docker stop ${container} && \
    log "${container}${FONT_GREEN} ... ok${FONT_NORMAL}" "[DOCKER][container-stop]" || \
    log "${container}${FONT_RED} ... failed${FONT_NORMAL}" "[DOCKER][container-stop]"
  done
}

function docker_remove_all_containers() {
  for container in `docker ps -a | tail -n +2 | awk '{print $1}'`
  do
    docker rm ${container} && \
    log "${container}${FONT_GREEN} ... ok${FONT_NORMAL}" "[DOCKER][container-remove]" || \
    log "${container}${FONT_RED} ... failed${FONT_NORMAL}" "[DOCKER][container-remove]"
  done
}

function docker_build_from_repo {
  local _repo_url=$1
  local _dest_dir=$2
  local _tag_str=$3 #Name and optionally a tag in the 'name:tag' format

  get_or_update_git_repo "${_repo_url}" "${_dest_dir}"

  if change_dir "${_dest_dir}"
  then
    docker build -t "${_tag_str}" . && \
    ( log "${container}${FONT_GREEN} ... OK${FONT_NORMAL}" "[DOCKER][build]"; return 0 ) || \
    ( log "${container}${FONT_RED} ... ERROR${FONT_NORMAL}" "[DOCKER][build]"; return 1 )
  fi
}

function set_docker_storage() {
  # https://sanenthusiast.com/change-default-image-container-location-docker/

  local _storage_dir=$1 #sample:-/opt/docker_volume
  local _service_unit='/etc/systemd/system/docker.service.d/docker.conf'
  local _service_unit_content=`cat << EOL
[Service]
Environment="DOCKER_STORAGE_OPTIONS=--storage-driver=overlay"
Environment="DOCKER_RUNTIME_OPTIONS=--graph=${_storage_dir}"
ExecStart=
ExecStart=/usr/bin/dockerd \\${DOCKER_STORAGE_OPTIONS} \\${DOCKER_RUNTIME_OPTIONS}
EOL
`

  systemctl stop docker

  create_dir "`dirname ${_service_unit}`"
  overwrite_content "${_service_unit_content}" "${_service_unit}"

  systemctl daemon-reload
  systemctl start docker
}