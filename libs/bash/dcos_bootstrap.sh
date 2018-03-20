#!/usr/bin/env bash

. ./file_and_dir.sh
. ./sed.sh

##DEFAULT_REMOTE_UNIVERSE='universe.mesosphere.com/repo'
#
#EXEC_HOME='/usr/local/bin'
#
#CLI_DOWNLOAD='https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.10/dcos'
#
#UNIVERSAL_SRV_DOWNLOAD='https://github.com/mesosphere/universe.git --branch version-3.x'
#UNIVERSAL_SRV_SRC="${SRC_HOME}/universal_server"
#
#UNIVERSE_HTTP='dcos-local-universe-http'
#UNIVERSE_HTTP_DOWNLOAD="https://raw.githubusercontent.com/mesosphere/universe/version-3.x/docker/local-universe/${UNIVERSE_HTTP}.service"
#
#UNIVERSE_REGISTRY='dcos-local-universe-registry'
#UNIVERSE_REGISTRY_DOWNLOAD="curl -v https://raw.githubusercontent.com/mesosphere/universe/version-3.x/docker/local-universe/${UNIVERSE_REGISTRY}.service"
#
#UNIVERSE_NODE='192.168.201.108'
#MASTER_NODE='192.168.201.101'

function download_dcos_generate_config {
  local _dest=$1

  create_dir "${_dest}"
  curl -o ${_dest}/dcos_generate_config.sh https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh
}

function create_ip_detect_script {
  local _route_dest=$1
  local _script="$2/ip-detect"

  local _content=`cat << EOF
#!/usr/bin/env bash
export LANG=C.UTF-8

release="\\$(uname -r)"

# aws private
# curl -fsL http://169.254.169.254/latest/meta-data/local-ipv4 && echo && exit 0
## # aws public
##  curl -fsL http://instance-data/latest/meta-data/public-ipv4 && echo && exit 0
## curl -fsL http://169.254.169.254/latest/meta-data/public-ipv4 && echo && exit 0

[[ \\$release = *"coreos"* ]] && ip route get ${_route_dest} | awk '{print \\$5; exit}' && exit 0

ip route get ${_route_dest} | awk '{print \\$6; exit}' && exit 0

EOF`

  create_dir "$2"
  overwrite_content "${_content}" "${_script}"
}

function create_dcos_config {
  local _bootstrap_host=$2
  local _bootstrap_port=$3

  declare -a _master_list=("${!4}")

  local _cluster_name="dcos-test"
  local _ssh_user="admin"

  local _config="$1/config.yaml"
  local _content=`cat << EOF
---
bootstrap_url: http://${_bootstrap_host}:${_bootstrap_port}
cluster_name: ${_cluster_name}
exhibitor_storage_backend: static
master_discovery: static
ip_detect_public_filename: genconf/ip-detect
master_list:
resolvers:
- 8.8.8.8
- 8.8.4.4
ssh_port: 22
ssh_user: ${_ssh_user}
process_timeout: 10000
oauth_enabled: 'false'

EOF`

  overwrite_content "${_content}" "${_config}"

  for master in ${_master_list[@]}; do
    echo ${master}
    add_line_after_match "^master_list:" "- ${master}" "${_config}"
  done
}

function uninstall_dcos {
  for i in `find /* -name *dcos*`; do echo $i | grep -P '\bdcos' | xargs rm -rf ; done
  for i in `find /* -name *_dcos*`; do echo $i | xargs rm -rf ; done
  for i in `find /* -name *mesos*`; do echo $i | grep -P '\bmesos' | xargs rm -rf ; done
  for i in `find /* -name *_mesos*`; do echo $i | xargs rm -rf ; done
}

function run_dcos_generate_config {
  local _run_dir=$1

  change_dir "${_run_dir}"
  sh ./dcos_generate_config.sh
}

function run_dcos_bootstrap_nginx {
  local _expose_port=$1
  local _dcos_dir=$2

  echo "docker run -d -p $_expose_port:80 -v ${_dcos_dir}/genconf/serve:/usr/share/nginx/html:ro nginx"
  docker run -d -p $_expose_port:80 -v ${_dcos_dir}/genconf/serve:/usr/share/nginx/html:ro nginx
}

DCOS_BOOTSTRAP_HOME="/opt/dcos_bootstrap"
BOOTSTRAP_HOST="172.27.11.110"
BOOTSTRAP_PORT="10080"
MASTER_LIST=("172.27.11.110")

download_dcos_generate_config "${DCOS_BOOTSTRAP_HOME}"
create_ip_detect_script "${BOOTSTRAP_HOST}" "${DCOS_BOOTSTRAP_HOME}/genconf"
create_dcos_config "${DCOS_BOOTSTRAP_HOME}/genconf" "${BOOTSTRAP_HOST}" "${BOOTSTRAP_PORT}" "MASTER_LIST[@]"

#. ./docker.sh
#set_docker_storage "/opt/docker_volume"

run_dcos_generate_config "${DCOS_BOOTSTRAP_HOME}"

run_dcos_bootstrap_nginx "${BOOTSTRAP_PORT}" "${DCOS_BOOTSTRAP_HOME}"


