. ./log.sh
. ./git.sh
. ./file_and_dir.sh
. ./default_paths.sh

# https://www.centos.bz/2017/01/dockerd-launch-the-docker-daemon/
# http://www.dockerinfo.net/2889.html
# http://www.zoues.com/2017/06/23/译见-奇妙的-docker-使用技巧十连发【zoues-com】/

function create_docker_repo_file {
  local _repo_config='/etc/yum.repos.d/docker.repo'
  local _config_content=`cat << EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/\\$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF`

  overwrite_content "${_config_content}" "${_repo_config}"
}

function install_docker_engine {
  yum install docker-engine

  systemctl enable docker
  systemctl start docker
}

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

function docker_build_image {
  local _build_dir=$1
  local _tag=$2

  if change_dir "${_build_dir}"
  then
    docker build -t "${_tag}" . && \
    ( log "${container}${FONT_GREEN} ... OK${FONT_NORMAL}" "[DOCKER][build]"; return 0 ) || \
    ( log "${container}${FONT_RED} ... ERROR${FONT_NORMAL}" "[DOCKER][build]"; return 1 )
  fi
}

function docker_build_from_repo {
  local _repo_url=$1
  local _dest_dir=$2
  local _tag_str=$3 #Name and optionally a tag in the 'name:tag' format

  get_or_update_git_repo "${_repo_url}" "${_dest_dir}"

  docker_build_image "${_dest_dir}" "${_tag_str}"
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

function compress_docker_credential {
  local _user=$1
  local _pass=$2
  local _docker_host=$3 #quay.io
  local _dest_dir=$4 #/etc

  docker login --username=${_user} --password=${_pass} ${_docker_host}

  cd ~
  tar -czf docker.tar.gz .docker
  tar -tvf ~/docker.tar.gz
  cp docker.tar.gz ${_dest_dir}/
}

function disable_docker_restart_always {
  docker update --restart=no $(docker ps -a -q)
}

function clean_docker_space {
  # Clean volumes
  docker volume ls -qf dangling=true | xargs docker volume rm

  # Clean images
  docker rmi $(docker images -f dangling=true -q)

  # Clean containers
  docker rm $(docker ps -a -q)
}

function find_docker_child_images {
  local _image_id=$1

  docker inspect --format='{{.Id}} {{.Parent}}' $(docker images --filter since=${_image_id} -q)
}

function get_docker_command {
  docker inspect  -f "{{.Name}} {{.Config.Cmd}}" $(docker ps -a -q)
}

function setup_docker_registry {
  # https://philipzheng.gitbooks.io/docker_practice/content/repository/local_repo.html
  docker run -d -p 5000:5000 --name registry registry:2
}

function add_insecure_docker_registry {
  local _registry_host=$1
  local _config="${DOCKER_DAEMON_CONFIG}"
  local _content=`cat << EOF
{
    "insecure-registries": [
        "${_registry_host}:5000"
    ]
}
EOF`
}

function docker_nest_docker {
  # https://github.com/moby/moby/blob/master/hack/dind
  # This script should be executed inside a docker container in privileged mode
  mount -t securityfs none /sys/kernel/security
}

function docker_run_docker {
#  http://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/
  docker run -v /var/run/docker.sock:/var/run/docker.sock -it dcos/setup /bin/bash
}

function check_docker_config {
  # https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh
  :
}