. ./file_and_dir.sh
. ./default_paths.sh

function setup_interface() {
  local _content=`cat << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth0 inet dhcp
EOF`
  overwrite_content "${_content}" "${NETWORK_INTERFACE_CONFIG}"
}
