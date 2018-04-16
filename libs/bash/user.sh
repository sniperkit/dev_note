. ./configs.sh

function set_userpass_with_encrytion() {
  local _user=$1
  local _pass=$2

  a_pass=$(echo fubar | mkpasswd) && \
  echo "${_user}:${_pass}" | chpasswd
}
