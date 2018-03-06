. ./log.sh

function docker_stop_all_containers() {
  for container in `docker ps | tail -n +2 | awk '{print $1}'`; do
    docker stop ${container} && \
    log "${FONT_GREEN} ... ok${FONT_NORMAL}" "[DOCKER][container-stop]" || \
    log "${FONT_RED} ... failed${FONT_NORMAL}" "[DOCKER][container-stop]"
  done
}

function docker_remove_all_containers() {
  for container in `docker ps -a | tail -n +2 | awk '{print $1}'`; do
    docker rm ${container} && \
    log "${container}${FONT_GREEN} ... ok${FONT_NORMAL}" "[DOCKER][container-remove]" || \
    log "${container}${FONT_RED} ... failed${FONT_NORMAL}" "[DOCKER][container-remove]"
  done
}