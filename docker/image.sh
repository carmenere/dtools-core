#  FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]

# Doc:
#   NO_CACHE: build without any cache
#   docker_build_args=(FOO BAR)
#   docker_build_args => "--env FOO=222 --env BAR=333"
ctx_docker_image() {
  DEFAULT_IMAGE="alpine:3.21"
  BUILD_ARGS=
  CTX="."
  DEFAULT_TAG=$(docker_default_tag)
  DOCKERFILE=
  IMAGE=
  NO_CACHE=
  REGISTRY="example.com"
  # Depends on DEFAULT_IMAGE and REGISTRY
  BASE_IMAGE=$(docker_base_image)
  # Hooks
  hook_pre_docker_build=
  docker_build_args=()
}

function docker_base_image() {
  local image="${REGISTRY}/build/${DEFAULT_IMAGE}"
  if [ "$(uname -m)" = "arm64" ]; then
    local image="arm64v8/${DEFAULT_IMAGE}"
  fi
  echo ${image}
}

function docker_default_tag() {
  tag="v0.0.1"
  if [ "$(uname -m)" = "arm64" ]; then
    tag="v0.0.1-arm64"
  fi
  echo ${tag}
}

function docker_pull_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -n "${IMAGE}" ]; then cmd+=("${IMAGE}"); else dt_error ${fname} "Var 'IMAGE' is empty"; return 99; fi
}

function _docker_build_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "${DOCKERFILE}" ]; then dt_error ${fname} "Var 'DOCKERFILE' is empty"; return 99; fi
  if [ -z "${IMAGE}" ]; then dt_error ${fname} "Var 'IMAGE' is empty"; return 99; fi
  if [ -z "${CTX}" ]; then dt_error ${fname} "Var 'CTX' is empty"; return 99; fi

  if [ "${NO_CACHE}" = "y" ]; then cmd+=(--no-cache); fi
  cmd+=(-f "${DOCKERFILE}")
  cmd+=(-t "${IMAGE}")
  cmd+=("${CTX}")
}

function _docker_build_arg_opts() {
  docker_build_args=($(echo ${docker_build_args}))
  for arg in ${docker_build_args[@]}; do
    if [ -z "$arg" ]; then continue; fi
    val=$(dt_escape_quote "$(eval echo "\$$arg")")
    if [ -n "${val}" ]; then cmd+=(--build-arg "${arg}=$'${val}'"); fi
  done
}

function docker_pull() {
  docker_is_running || return $?
  local cmd=(docker pull)
  docker_pull_opts && \
  dt_exec ${fname} "${cmd[@]}"
}

function docker_build() {
  docker_is_running || return $?
  local cmd=(docker build)
  $hook_pre_docker_build && \
  _docker_build_arg_opts && \
  _docker_build_opts && \
  dt_exec ${fname} "${cmd[@]}"
}

function docker_rmi() {
  docker_is_running || return $?
  local cmd=(docker rmi ${IMAGE})
  dt_exec ${fname} "${cmd[@]}"
}
