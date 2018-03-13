#!/usr/bin/env bash

. ./file_and_dir.sh

#DEFAULT_REMOTE_UNIVERSE='universe.mesosphere.com/repo'

EXEC_HOME='/usr/local/bin'

CLI_DOWNLOAD='https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.10/dcos'

UNIVERSAL_SRV_DOWNLOAD='https://github.com/mesosphere/universe.git --branch version-3.x'
UNIVERSAL_SRV_SRC="${SRC_HOME}/universal_server"

UNIVERSE_HTTP='dcos-local-universe-http'
UNIVERSE_HTTP_DOWNLOAD="https://raw.githubusercontent.com/mesosphere/universe/version-3.x/docker/local-universe/${UNIVERSE_HTTP}.service"

UNIVERSE_REGISTRY='dcos-local-universe-registry'
UNIVERSE_REGISTRY_DOWNLOAD="curl -v https://raw.githubusercontent.com/mesosphere/universe/version-3.x/docker/local-universe/${UNIVERSE_REGISTRY}.service"

UNIVERSE_NODE='192.168.201.108'
MASTER_NODE='192.168.201.101'

# create ip-detect.sh
function create_ip_detect_script {
  local _route_dest=$1
  local _script=$2

  local _content=`cat << EOF
#!/usr/bin/env bash
export LANG=C.UTF-8

release=`uname -r`

# aws private
# curl -fsL http://169.254.169.254/latest/meta-data/local-ipv4 && echo && exit 0
## # aws public
##  curl -fsL http://instance-data/latest/meta-data/public-ipv4 && echo && exit 0
## curl -fsL http://169.254.169.254/latest/meta-data/public-ipv4 && echo && exit 0

[[ \$release = *"coreos"* ]] && ip route get ${_route_dest} | awk '{print \$5; exit}' && exit 0

ip route get ${_route_dest} | awk '{print \$6; exit}' && exit 0

EOF`

  overwrite_content "${_content}" "${_script}"
}

# create config.yaml
# start nginx and map port 10080:80

