. ./cmd.sh

# https://access.redhat.com/support/policy/updates/rhscl

IUS_REPO="https://centos7.iuscommunity.org/ius-release.rpm"

function yum_dryrun {
  local _dir=$1

  run_and_validate_cmd "yum -y --disablerepo=* localinstall ${_dir}/*.rpm --setopt tsflags=test"
}

function yum_install {
  local pkg=$1

  yum install $pkg && \
  log "$pkg ... ${FONT_GREEN}ok${FONT_NORMAL}" "[YUM][install]" || \
  log "$pkg ... ${FONT_RED}failed${FONT_NORMAL}" "[YUM][install]"
}

function yum_download {
  local _method=$1
  local _package=$2
  local _dest_dir=$3


  if [[ ${_method} == 'update' ]]; then
    yum update --downloadonly --downloaddir=${_dest_dir}
  fi

  if [[ ${_method} == 'install' ]]; then
    yum install ${_package} --downloadonly --downloaddir=${_dest_dir}
  fi
}

function yum_enable_cr_repo {
  yum_install "yum-utils"

  yum-config-manager --enable cr
}

function get_yum_available_in_repos {
  local _path_prefix=${1:-/tmp/available_pkgs}
  local _repos=( "http://linux.mirrors.es.net/centos/7/os/x86_64/Packages/" \
                 "http://linux.mirrors.es.net/centos/7.4.1708/os/x86_64/Packages/" \
                 "http://linux.mirrors.es.net/centos/7.3.1611/os/x86_64/Packages/" \
                 "http://mirror.centos.org/centos/7/updates/x86_64/Packages/" \
                 "http://mirror.centos.org/centos/7/cr/x86_64/Packages/" \
                 "https://yum.dockerproject.org/repo/main/centos/7/Packages/" \
                 "https://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/")

  # get available package in repo
  local _cntr=0
  for repo in "${_repos[@]}"
  do
     _cntr=$(($_cntr+1))
     echo $repo > "${_path_prefix}"_"${_cntr}".html
     curl $repo >> "${_path_prefix}"_"${_cntr}".html
  done
}

function search_pkgs_in_repos {
  local _pkg_dir=$1
  local _path_prefix=${2:-/tmp/available_pkgs}
  local _matched_repo=${3:-/tmp/match_yum_pkgs.txt}

  get_yum_available_in_repos "${_path_prefix}"

  ls -f ${_pkg_dir} | while read pkg
  do
    #---- calculate md5 -------------------------------------#
    local _pkg_md5sum=`md5sum ${_pkg_dir}/${pkg} | awk '{print $1}'`

    #---- search package list file -------#
    repo_url=''
    for _file in ${_path_prefix}*
    do
      if_match=`grep ${pkg} ${_file}`

      [[ $if_match ]] &&
      repo_url=$(head -n 1 ${_file}) &&
      break
    done

    #---- write match to file -----------------------------------#
    echo "${_pkg_md5sum}  $repo_url  ${pkg}" >> ${_matched_repo}
  done

  #*** rm unnecessary line ***#
  sed -i "/^  /d" ${_matched_repo}
}

# others
function update_pkg_bom_file() {
  local _search_dir=$1
  local _matched_repo=$2
  local _bom_file=$3
  local _output_dir=`dirname ${_bom_file}`
  local _not_found="${_output_dir}/unfind_inbom.txt"
  local _found="${_output_dir}/find_inbom.txt"

  ls ${_search_dir} | while read pkg
  do
    findline=`search_match "${_search_dir}/${pkg}" "${_bom_file}"`

    #---- update bom file ------------------#
    echo ${findline}
    [[ ! $findline ]] && echo ${pkg} >> ${_not_found}
    [[ ! $findline ]] && add_pkg_to_bom_block "${pkg}" "${_matched_repo}" "${_bom_file}"

    [[ $findline ]] && echo ${pkg} >> ${_found}
    [[ $findline ]] && update_bom_json_block "${findline}" "${pkg}" "${_matched_repo}" "${_bom_file}"

  done
}

search_match() {
  local _pkg_path=$1
  local _search_file=$2

  #*** init ********#
  local pkg_name=''
  local process_family=''
  local match_this=''
  local ret_line_num=''

  #*** get package detail ************************************************************************************#
  local pkg_name=`rpm -qip ${_pkg_path} | grep '^Name' | cut -d':' -f2 | awk '{print \$1}'`
  local process_family=`rpm -qip ${_pkg_path} | grep '^Architecture' | cut -d':' -f2 | awk '{print \$1}'`

  #*** find match and return line number *********************#
  local match_this='"'$pkg_name'-[0-9].*\.'$process_family'\.rpm"'
  local line_number=`grep -n $match_this ${_search_file} | cut -d':' -f1`
  echo "$line_number"
}

add_pkg_to_bom_block() {
  local _pkg=$1
  local _matched_repo=$2
  local _bom_file=$3
  # local pkg_name=`rpm -qip $dl_rpm_dir/$rpm_file | head -n1 | cut -d':' -f2 | awk '{print $1}'`
  echo "grep ' '${_pkg} ${_matched_repo} | awk '{print $1}'"
  local _pkg_md5=`grep ' '${_pkg} ${_matched_repo} | awk '{print $1}'`
  local _pkg_url=`grep ' '${_pkg} ${_matched_repo} | awk '{print $2}'`

  echo "Add ${_pkg} ..."

  # append to file
  sed -i "2i\ \ \ \ }," ${_bom_file}
  sed -i "2i\ \ \ \ \ \ \ \ ]" ${_bom_file}
  sed -i "2i\ \ \ \ \ \ \ \ \ \ \ \ \"${_pkg_url}\"" ${_bom_file}
  sed -i "2i\ \ \ \ \ \ \ \ \"repos\": [" ${_bom_file}
  sed -i "2i\ \ \ \ \ \ \ \ \"md5sum\": \"${_pkg_md5}\"," ${_bom_file}
  sed -i "2i\ \ \ \ \"${_pkg}\": {" ${_bom_file}
}

update_bom_json_block() {
  findline_pkg=$1
  findline_md5sum=$(( $1 + 1 ))
  findline_url=$(( $1 + 3 ))

  update_pkg_with=$2
  local _matched_repo=$3
  update_md5_with=`grep ' '$update_pkg_with $_matched_repo | awk '{print $1}'`
  update_url_with=`grep ' '$update_pkg_with $_matched_repo | awk '{print $2}'`

  local _bom_file=$4

  echo "Replace $update_pkg_with ..."

  #*** replace lines *****************************************#
  replace_pkg_str=$findline_pkg's/.*/    \"'$update_pkg_with'\": {/'
  replace_md5_str=$findline_md5sum's/.*/        \"md5sum\": \"'$update_md5_with'\",/'
  replace_url_str=$findline_url's,.*,            \"'$update_url_with'\",'

  sed -i "$replace_pkg_str" $_bom_file
  sed -i "$replace_md5_str" $_bom_file
  sed -i "$replace_url_str" $_bom_file
}


#yum_download "install" "docker-engine" "/opt/download_docker_engine"
#search_pkgs_in_repos "/opt/download_docker_engine" "/opt/tmp_bom/available_pkgs" "/opt/tmp_bom/match_yum_pkgs.txt"
#update_pkg_bom_file "/opt/download_docker_engine" "/opt/tmp_bom/match_yum_pkgs.txt" "/opt/tmp_bom/pkg_bom.json"

#. ./file_and_dir.sh
#sort_file "/opt/tmp_bom/pkg_bom.json" "json"

#yum_download "install" "python36u" "/opt/download_python36u"
#search_pkgs_in_repos "/opt/download_python36u" "/opt/tmp_bom/available_pkgs" "/opt/tmp_bom/match_yum_pkgs.txt"
#update_pkg_bom_file "/opt/download_python36u" "/opt/tmp_bom/match_yum_pkgs.txt" "/opt/tmp_bom/pkg_bom.json"
#
. ./file_and_dir.sh
sort_file "/opt/tmp_bom/pkg_bom.json" "json"

