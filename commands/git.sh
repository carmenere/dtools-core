function git_dir() {
  local dir
  dir="$(git rev-parse --git-dir)" || return $?
  echo "${dir}"
}

function git_branch() {
  local branch
  branch="$(git branch --show-current)" || return $?
  echo $branch
}

function git_commit_short() {
  local commit
  commit=$(git rev-parse --short HEAD) || return $?
  echo ${commit}
}

function git_commit() {
  local commit
  commit=$(git rev-parse HEAD) || return $?
  echo ${commit}
}

# $1 => ${commit}
# By default it takes CURRENT commit (HEAD) if commit is NOT provided ($1 is empty).
function git_tag_by_commit() {
  local commit tag
  set +u; commit="$1"; set -u
  if [ -z "${commit}" ]; then
    commit="$(git_commit)" || return $?
  fi
  tag=$(git tag --points-at "${commit}") || return $?
  if [ -z "${tag}" ]; then return 0; fi
  echo ${tag}
}

# $1 => ${tag}
# It returns ${commit} corresponding to ${tag}.
# It returns NOTHING if tag is NOT provided ($1 is empty) OR current commit has no tag OR ${tag} doesn't exist.
# By default it uses tag of CURRENT commit (if tag is NOT provided).
function git_commit_by_tag() {
  local commit tag
  set +u; tag="$1"; set -u
  if [ -z "${tag}" ]; then
    tag="$(git_tag_by_commit)" || return $?
  fi
  if [ -z "${tag}" ]; then return 0; fi
  commit=$(git rev-list -n 1 "${tag}") || return $?
  if [ -z "${commit}" ]; then return 0; fi
  echo ${commit}
}

# git_describe_tags may return "v1.x.y-N-g10aabbccff" or "v1.x.y" or NOTHING.
# It returns "v1.x.y" if tag "v1.x.y" directly points to current commit.
# It returns "v1.x.y-N-g10aabbccff" if tag "v1.x.y" behind N commits of current commit 10aabbccff.
# It returns NOTHING if no tag exist.
function git_describe_tags() {
  local tag
  tag=$(git describe --tags 2>/dev/null) || return $?
  if [ -z "${tag}" ]; then return 0; fi
  echo ${tag}
}

# It returns NON-empty string if uncommitted changes exist in working directory.
# It returns EMPTY string if NO uncommitted changes exist in working directory.
function git_status_porcelain() {
  local changes
  changes=$(git status --porcelain) || return $?
  if [ -z "${changes}" ]; then return 0; fi
  echo ${changes}
}

# 1) If git_describe_tags returns v1.x.y it means git_tag_by_commit will return the same value v1.x.y.
# 2) If [ -z $(git_status_porcelain) ] is TRUE it means NO uncommitted changes exist in working directory.
function git_release_version() {
  local tag
  tag=$(git_describe_tags)
  if [ -z "$(git_status_porcelain)" ] && [ -n "${tag}" ] && [ "${tag}" = "$(git_tag_by_commit)" ]; then
    echo "${tag}"
  fi
}

function git_build_version() {
  if [ -n "$(git_release_version)" ]; then
    echo $(git_release_version)
  elif [ -z "$(git_status_porcelain)" ] && [ -n "$(git_commit)" ]; then
    echo "$(git_commit)"
  elif [ -n "$(git_branch)" ]; then
    echo "$(git_branch)"
  else
    echo "unknown"
  fi
}
