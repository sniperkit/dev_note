. ./log.sh
. ./file_and_dir.sh

function get_or_update_git_repo() {
  local repo_url=$1
  local dest_dir=$2

  if change_dir "${dest_dir}"; then
    [[ ! -d .git ]] && return 1

    git pull && \
    ( log "${dest_dir} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][pull]"; return 0 ) || \
    ( log "${dest_dir} ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][pull]"; return 1 )

  else
    git clone ${repo_url} ${dest_dir} && \
    ( log "${repo_url} ... ${FONT_GREEN}ok${FONT_NORMAL}" "[GIT][clone]"; return 0 ) || \
    ( log "${repo_url} ... ${FONT_RED}failed${FONT_NORMAL}" "[GIT][clone]"; return 1 )
  fi
}
