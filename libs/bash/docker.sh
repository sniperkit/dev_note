. ./log.sh
. ./git.sh
. ./file_and_dir.sh
. ./default_paths.sh
. ./openssl.sh

# https://www.centos.bz/2017/01/dockerd-launch-the-docker-daemon/
# http://www.dockerinfo.net/2889.html
# http://www.zoues.com/2017/06/23/译见-奇妙的-docker-使用技巧十连发【zoues-com】/
# https://stackoverflow.com/questions/31205438/docker-on-windows-boot2docker-certificate-signed-by-unknown-authority-error
# https://stackoverflow.com/questions/26924766/docker-client-cant-read-from-both-docker-private-registry-and-online-docker
# https://gist.github.com/christianberg/eaec4028fbb77a0c3c8c

DOCKER_IO_REGISTRY_CRT='https://auth.docker.io/token?scope=repository%3Alibrary%2Fhello-world%3Apull&service=registry.docker.io'

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
  local _registry_host=$2
  local _service_unit='/etc/systemd/system/docker.service.d/override.conf'
  local _service_unit_content=`cat << EOL
[Service]
Environment="DOCKER_STORAGE_OPTIONS=--storage-driver=overlay"
Environment="DOCKER_RUNTIME_OPTIONS=--graph=${_storage_dir}"
Environment="DOCKER_INSECURE_OPTION=--insecure-registry=${_registry_host}:5000"
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

function setup_docker_registry_simple {
  # https://philipzheng.gitbooks.io/docker_practice/content/repository/local_repo.html
  # https://kairen.github.io/2016/01/02/container/docker-registry/
  docker run -d -p 5000:5000 --name registry registry:2
}

function setup_docker_registry_with_credential {
  # https://stackoverflow.com/questions/38247362/how-i-can-use-docker-registry-with-login-password
#  docker run -d -p 5000:5000 --name registry registry:2
  local _auth_dir='/etc/docker/registry/auth'
  mkdir -p ${_auth_dir}
  docker run --entrypoint htpasswd registry:2 -Bbn admin '@dmin!234' > ${_auth_dir}/htpasswd
  docker run -d -p 5000:5000 \
  --name registry_private \
  -v ${_auth_dir}:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  registry:2
}

function setup_docker_registry_with_tls {
  # https://stackoverflow.com/questions/38247362/how-i-can-use-docker-registry-with-login-password
#  docker run -d -p 5000:5000 --name registry registry:2
  local _cert_dir='/etc/docker/registry/certs'
  mkdir -p ${_cert_dir}
  docker run -d --name registry_private -v ${_cert_dir}:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key -p 5000:5000 registry:2
  # on dest node
  # mkdir -p /etc/docker/certs.d/172.27.11.167:5000
  # scp ./certs/domain.crt root@172.27.11.164:/etc/docker/certs.d/172.27.11.167:5000
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

function get_docker_registry {
  curl -X GET https://172.27.11.167:5000/v2/_catalog
}

function del_docker_registry_image {
  curl -X DELETE localhost:5000/v1/repositories/ubuntu/tags/latest
}

function set_private_registry_with_tls {
  cd /etc/docker/registry
  set_openssl_crt_with_ip_san
  docker run -d --name registry_private -v /etc/docker/registry/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key -p 5000:5000 registry:2
}