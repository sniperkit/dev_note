. ./file_and_dir.sh

function setup_interface() {
  local _content=`cat << EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth0 inet dhcp
EOF`
  overwrite_content "${_content}" "/etc/network/interfaces"
}
