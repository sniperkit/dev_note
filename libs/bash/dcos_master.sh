#!/usr/bin/env bash
. ./file_and_dir.sh

# <troubleshooting:1.11> https://docs.mesosphere.com/1.11/installing/oss/troubleshooting/

function download_dcos_install {
  local _bootstrap_node=$1
  local _dest=$2

  create_dir "${_dest}"
  curl -o ${_dest}/dcos_install.sh http://${_bootstrap_node}/dcos_install.sh
}

function deploy_dcos_master_node {
  local _run_dir=$1

  change_dir "${_run_dir}"
  sudo sh ./dcos_install.sh master
}

DCOS_MASTER_HOME="/opt/dcos_master"
DCOS_BOOTSTRAP_HOME="/opt/dcos_bootstrap"

. ./dcos_bootstrap.sh
#BOOTSTRAP_HOST=$1
#BOOTSTRAP_PORT="10080"

#download_dcos_install "${BOOTSTRAP_HOST}:${BOOTSTRAP_PORT}" ${DCOS_MASTER_HOME}

#groupadd nogroup

#if is bootstrap node
#. ./sed.sh
#escaped_str=`escape_forward_slash "docker run -d -p ${BOOTSTRAP_PORT}:80 -v ${DCOS_BOOTSTRAP_HOME}/genconf/serve:/usr/share/nginx/html:ro nginx"`
#add_line_after_match "^systemctl restart docker" "${escaped_str}" "/opt/dcos_master/dcos_install.sh"
#

#. ./ntp.sh
#setup_ntp
#
deploy_dcos_master_node "${DCOS_MASTER_HOME}"
