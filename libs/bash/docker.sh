. ./log.sh
. ./git.sh
. ./file_and_dir.sh

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