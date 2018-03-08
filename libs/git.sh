. ./log.sh

function get_or_update_git_repo() {
  local repo_url=$1
  local dest_dir=$2

  if [[ `ls -A ${dest_dir} 2>/dev/null` ]]; then
    pushd ${dest_dir} && git pull && popd && \
    log "${dest_dir} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][pull]" || \
    log "${dest_dir} ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][pull]"
  else
    git clone ${repo_url} ${dest_dir} && \
    log "${repo_url} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][clone]" || \
    log "${repo_url} ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][clone]"
  fi
}
