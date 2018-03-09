#!/usr/bin/env bash
. ./utils.sh
. ./configs.sh

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

function setup_cli () {
  change_dir "${EXEC_HOME}"
  curl -O $CLI_DOWNLOAD
  set_permission "0700" "${EXEC_HOME}/dcos"
  remount_exec "/tmp"

  dcos cluster setup http://${MASTER_NODE}
}

function add_package_repo() {
#  dcos package repo add local-universe http://${UNIVERSE_NODE}:8082/repo

  dcos package repo add local-universe http://master.mesos:8082/repo
}

function setup_universe_registry() {
  curl -v "${UNIVERSE_HTTP_DOWNLOAD}" -o "${UNIVERSE_HTTP}.service"
  curl -v "${UNIVERSE_REGISTRY_DOWNLOAD}" -o "${UNIVERSE_REGISTRY}.service"

}

function setup_universe_image() {
  yum_setup_python3 "3.5"

  change_dir "${UNIVERSAL_SRV_SRC}/docker/local-universe/"
  make base

  make DCOS_VERSION=1.10 DCOS_PACKAGE_INCLUDE="cassandra:1.0.25-3.0.10,marathon:1.4.2" local-universe
}

function load_universe_container() {
  change_dir "${UNIVERSAL_SRV_SRC}/docker/local-universe/"
  docker load < local-universe.tar.gz
}

function setup_universe_http() {
  change_dir "${UNIVERSAL_SRV_SRC}/"
#  copy_file_or_dir "${UNIVERSE_REGISTRY}.service" "/etc/systemd/system/${UNIVERSE_REGISTRY}.service"
  copy_file_or_dir "${UNIVERSE_HTTP}.service" "/etc/systemd/system/${UNIVERSE_HTTP}.service"
}

function start_universe_http() {
  systemctl daemon-reload
#  do_service "${UNIVERSE_REGISTRY}" "start"
  do_service "${UNIVERSE_HTTP}" "start"
}

function stop_universe_http() {
  do_service "${UNIVERSE_HTTP}" "stop"
}

function sample_package() {
  local _project=$1

  get_or_update_repo "https://${username}@bitbucket.org/${repo}/${_project}.git" "${SRC_HOME}/${_project}"

  change_dir "${SRC_HOME}/${_project}"
  docker build -t ${project}:${tag} .

#  https://github.com/mesosphere/universe/blob/version-3.x/scripts/local-universe.py
#  vi /opt/src/universal_server/docker/local-universe/../../scripts/local-universe.py
#  for name in enumerate_docker_images(path):
#     download_docker_image(name)
}

function set_docker_download_trust() {
  sudo mkdir -p /etc/docker/certs.d/master.mesos:5000
  sudo curl -o /etc/docker/certs.d/master.mesos:5000/ca.crt http://master.mesos:8082/certs/domain.crt
  sudo systemctl restart docker

  sudo cp /etc/docker/certs.d/master.mesos:5000/ca.crt /var/lib/dcos/pki/tls/certs/docker-registry-ca.crt
  cd /var/lib/dcos/pki/tls/certs/
  local _hash=`openssl x509 -hash -noout -in docker-registry-ca.crt`
  sudo ln -s /var/lib/dcos/pki/tls/certs/docker-registry-ca.crt /var/lib/dcos/pki/tls/certs/$_hash.0
}

function main() {
#  setup_cli
#
#  get_or_update_repo "${UNIVERSAL_SRV_DOWNLOAD}" "${UNIVERSAL_SRV_SRC}"

#  stop_universe_http
  setup_universe_image
#  load_universe_container
#  setup_universe_http
#  start_universe_http
#  add_package_repo
}

main

#PREREQUISITE:
#- docker image (in this case used dockerfile in xxx )
#- dcos cli (optional: used to point to universal server, can also use GUI)
#
#STEP:
#NODE: any
#1. clone https://github.com/mesosphere/universe.git --branch version-3.x
#2. Add packages directory to universe
#+-- repo/package/D
#  +-- xxx
#    +-- 0
#      +-- config.json
#      +-- marathon.json.mustache
#      +-- package.json
#      +-- resource.json

#3. Setup universe image tar file
#
#NODE: master
#1. load universe container
#2. start dcos-local-universe-http
#3. start dcos-local-universe-registry
#4. point to universe repo url
#
#NOTE:
#makefile will try to pull image from registry during universe image setup, for this case we do not have a registry
#server setup, comment out download_docker_image in <UNIVERSAL_SERVER_DIR>/scripts/local-universe.py
#    122                 for name in enumerate_docker_images(path):
#    123                     # download_docker_image(name)
#    124                     upload_docker_image(name)
