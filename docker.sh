#  FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]
docker_image_special=(hook_pre_docker_build docker_build_args)
docker_image_vars=(DEFAULT_IMAGE BUILD_ARGS CTX DEFAULT_TAG DOCKERFILE BASE_IMAGE IMAGE NO_CACHE REGISTRY ${docker_image_special[@]})
docker_container_special=(hook_pre_docker_run docker_run_envs)
docker_container_vars=(ATTACH BACKGROUND PSEUDO_TTY PUBLISH REGISTRY RESTART RM SH STDIN COMMAND CONTAINER ${docker_container_special[@]})
docker_network_vars=(SUBNET BRIDGE ERR_IF_BRIDGE_EXISTS DRIVER)
docker_vars=(${docker_image_vars[@]} ${docker_container_vars[@]} ${docker_network_vars[@]})

function ctx_docker_network() {
  local ctx=$0; dt_skip_if_initialized || return $?
  __vars=("${docker_network_vars}")
  SUBNET="192.168.111.0/24"
  BRIDGE="example"
  ERR_IF_BRIDGE_EXISTS="n"
  DRIVER="bridge"
  dt_set_ctx -c ${ctx}
}

# Doc:
#   NO_CACHE: build without any cache
#   docker_build_args=(FOO BAR)
#   docker_build_args => "--env FOO=222 --env BAR=333"
ctx_docker_image() {
  local ctx=$0; dt_skip_if_initialized || return $?
  __vars=("${docker_image_vars}")
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
  dt_set_ctx -c ${ctx}
}

# Doc:
#   ATTACH: attach docker to current terminal (to STDIN, STDOUT or STDERR)
#   BACKGROUND: run in background
#   PSEUDO_TTY: allocate a pseudo-TTY
#   REGISTRY="example.com:5004"
#   RESTART="always"|"no"
#   RM: remove after stop
#   STDIN: keep STDIN open even if not attached
#   PUBLISH=()
#   PUBLISH+=("${PORT_11}:${PORT_33}/tcp")
#   PUBLISH+=("${PORT_22}:${PORT_44}/tcp")
#   docker_run_envs: array of envs that will be used for --env option, example: "--env VAR=VALUE"
#   docker_run_envs => "--env FOO=222 --env BAR=333"
ctx_docker_container() {
  local ctx=$0; dt_skip_if_initialized || return $?
  __vars=("${docker_container_vars}")
  ATTACH=
  BACKGROUND=
  PSEUDO_TTY=
  PUBLISH=()
  REGISTRY=
  RESTART=
  RM=
  SH="/bin/sh"
  STDIN=
  COMMAND=
  CONTAINER=
  # Hooks
  hook_pre_docker_run=
  docker_run_envs=()
  dt_set_ctx -c ${ctx}
}

function docker_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  SUDO=sudo
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec "${SUDO} apt-get update"
    dt_exec "${SUDO} apt-get install -y ca-certificates curl gnupg"
    dt_exec "${SUDO} install -m 0755 -d /etc/apt/keyrings"
    dt_exec "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg"
    dt_exec "${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg"
    dt_exec "echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "${VERSION_CODENAME}")" stable" | \
      ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null"
    dt_exec "${SUDO} apt-get update"
    dt_exec "${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function docker_post_install() {
  # post-install actions
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      ${SUDO} groupadd docker || true
      ${SUDO} usermod -aG docker ${USER}
  fi
}

function docker_base_image() {
  local img="${REGISTRY}/build/${DEFAULT_IMAGE}"
  if [ "$(uname -m)" = "arm64" ]; then
    local img="arm64v8/${DEFAULT_IMAGE}"
  fi
  echo $img
}

function docker_default_tag() {
  tag="v0.0.1"
  if [ "$(uname -m)" = "arm64" ]; then
    tag="v0.0.1-arm64"
  fi
  echo $tag
}

function docker_pull_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -n "${IMAGE}" ]; then cmd+=("${IMAGE}"); else dt_error ${fname} "Var 'IMAGE' is empty"; return 99; fi
}

function docker_build_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "${DOCKERFILE}" ]; then dt_error ${fname} "Var 'DOCKERFILE' is empty"; return 99; fi
  if [ -z "${IMAGE}" ]; then dt_error ${fname} "Var 'IMAGE' is empty"; return 99; fi
  if [ -z "${CTX}" ]; then dt_error ${fname} "Var 'CTX' is empty"; return 99; fi

  if [ "${NO_CACHE}" = "y" ]; then cmd+=(--no-cache); fi
  cmd+=(-f "${DOCKERFILE}")
  cmd+=(-t "${IMAGE}")
  cmd+=("${CTX}")
}

function _docker_run_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "${IMAGE}" ]; then dt_error ${fname} "Var 'IMAGE' is empty"; return 99; fi
  if [ "${ATTACH}" = "y" ]; then cmd+=(-a); fi
  if [ "${BACKGROUND}" = "y" ]; then cmd+=(-d); fi
  if [ "${PSEUDO_TTY}" = "y" ]; then cmd+=(-t); fi
  if [ "${RM}" = "y" ]; then cmd+=(--rm); fi
  if [ "${STDIN}" = "y" ]; then cmd+=(-i); fi
  if [ -n "${BRIDGE}" ]; then cmd+=(--network "${BRIDGE}"); fi
  if [ -n "${CONTAINER}" ]; then cmd+=(--name "${CONTAINER}"); fi
  if [ -n "${RESTART}" ]; then cmd+=(--restart "${RESTART}"); fi

  if [ -n "${IMAGE}" ]; then cmd+=("${IMAGE}"); fi
  if [ -n "${COMMAND}" ]; then cmd+=("${COMMAND}"); fi
}

function _docker_run_publish_opts() {
  if [ -z "${PUBLISH}" ]; then return 0; fi
  for publish in ${PUBLISH[@]}; do
    cmd+=(--publish "${publish}")
  done
}

function _docker_run_env_opts() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_run_envs=($(echo ${docker_run_envs}))
  for e in "${docker_run_envs[@]}"; do
    if [ -z "$e" ]; then continue; fi
    val=$(dt_escape_quote "$(eval echo "\$$e")")
    if [ -n "${val}" ]; then cmd+=(--env "${e}=$'${val}'"); fi
  done
}

function docker_build_arg_opts() {
  docker_build_args=($(echo ${docker_build_args}))
  for arg in ${docker_build_args[@]}; do
    if [ -z "$arg" ]; then continue; fi
    val=$(dt_escape_quote "$(eval echo "\$$arg")")
    if [ -n "${val}" ]; then cmd+=(--build-arg "${arg}=$'${val}'"); fi
  done
}

function docker_ps() {
  docker_is_running || return $?
  docker ps -a
}

function docker_is_running() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if ! docker ps 1>/dev/null; then dt_error ${fname} "${BOLD}Service docker is not run!${RESET}"; return 99; fi
}

function docker_pull() {
  docker_is_running || return $?
  local cmd=(docker pull)
  docker_pull_opts && \
  dt_exec "${cmd[@]}"
}

function docker_build() {
  docker_is_running || return $?
  local cmd=(docker build)
  $hook_pre_docker_build && \
  docker_build_arg_opts && \
  docker_build_opts && \
  dt_exec "${cmd[@]}"
}

function docker_exec() {
  echo "docker exec -ti ${CONTAINER}"
}

function docker_exec_sh() {
  docker_is_running || return $?
  dt_exec "docker exec -ti ${CONTAINER} /bin/sh"
}

function docker_network_create() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  local id="$(dt_exec "docker network ls -q --filter name="^${BRIDGE}$"")"
  if [ -n "${id}" ]; then
    if [ ${ERR_IF_BRIDGE_EXISTS} = "y" ]; then
      dt_error ${fname} "Bridge ${BOLD}${BRIDGE}${RESET} with id='${id}' exists and ERR_IF_BRIDGE_EXISTS=${BOLD}y${RESET}."
      return 99
    else
      dt_info ${fname} "Bridge ${BOLD}${BRIDGE}${RESET} with id='${id}' exists, skip create."
      return 0
    fi
  fi
  if [ -z "${BRIDGE}" ]; then dt_error ${fname} "Parameter BRIDGE is empty. Cannot create bridge."; return 99; fi
  local cmd=(docker network create)
  if [ -n "${DRIVER}" ]; then cmd+=(--driver=${DRIVER}); fi
  if [ -n "${SUBNET}" ]; then cmd+=(--subnet=${SUBNET}); fi
  cmd+=(${BRIDGE})
  dt_exec "${cmd[@]}"
}

function docker_network_rm() {
  docker_is_running || return $?
  local cmd=(docker network rm ${BRIDGE})
  dt_exec "${cmd[@]}"
}

function docker_network_ls() {
  docker_is_running || return $?
  local cmd=(docker network ls)
  dt_exec "${cmd[@]}"
}

function docker_run() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  docker_network_create || return $?
  local id="$(dt_exec "docker ps -aq --filter name="^${CONTAINER}$" --filter status=running")"
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${CONTAINER}${RESET} with id='${id}' is running, skip run."
    return 0
  fi
  local id="$(dt_exec "docker ps -aq --filter name="^${CONTAINER}$" --filter status=exited --filter status=created")"
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${CONTAINER}${RESET} with id='${id}' was created but is stopped now, so start it."
    local cmd=(docker start ${CONTAINER})
    dt_exec "${cmd[@]}"
    return 0
  fi
  local cmd=(docker run)

  $hook_pre_docker_run && \
  _docker_run_publish_opts && \
  _docker_run_env_opts && \
  _docker_run_opts && \
  dt_exec "${cmd[@]}"
}

function docker_start() {
  docker_is_running || return $?
  local cmd=(docker start ${CONTAINER})
  dt_exec "${cmd[@]}"
}

function docker_stop() {
  docker_is_running || return $?
  local cmd=(docker stop ${CONTAINER})
  dt_exec "${cmd[@]}"
}

function docker_rmi() {
  docker_is_running || return $?
  local cmd=(docker rmi ${IMAGE})
  dt_exec "${cmd[@]}"
}

function docker_rm() {
  docker_is_running || return $?
  local cmd=(docker rm --force ${CONTAINER})
  dt_exec "${cmd[@]}"
}

function docker_rm_all() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  if [ -z "$(dt_exec "docker ps -lq")" ]; then dt_info ${fname} "docker_rm_all(): nothing to delete."; return 0; fi
  local cmd=(docker rm --force $(docker ps -aq))
  dt_exec "${cmd[@]}"
}

function docker_status() {
  docker_is_running || return $?
  local cmd=(docker ps -a --filter name="^${CONTAINER}$")
  dt_exec "${cmd[@]}"
}

function docker_logs() {
  docker_is_running || return $?
  local cmd=(docker logs "${CONTAINER}")
  dt_exec "${cmd[@]}"
}

function docker_logs_save_to_logfile() {
  docker_is_running || return $?
  local cmd=(docker logs "${CONTAINER}" '>' "${DT_LOGS}/container-${CONTAINER}.log" '2>&1')
  dt_exec "${cmd[@]}"
}

function docker_prune() {
  docker_is_running || return $?
  docker_rm_all
  dt_exec "docker system prune --force"
  dt_exec "docker volume prune --force"
  dt_exec "docker network prune --force"
}

function docker_purge() {
  docker_is_running || return $?
  docker_rm_all
  dt_exec "docker system prune --force --all --volumes"
  dt_exec "docker volume prune --force"
  dt_exec "docker network prune --force"
  dt_exec "docker builder prune --force --all"
}

function docker_service_check() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cmd="$(docker_exec) ${CHECK_CMD}"
  container=${CONTAINER}
  for i in $(seq 1 30); do
    dt_info ${fname} "${BOLD}Waiting ${container} runtime${RESET}: attempt ${BOLD}$i${RESET} ... ";
    if dt_exec ${cmd}; then dt_info ${fname} "${BOLD}${container}${RESET} is up now"; break; fi
    sleep 1
  done
}

docker_methods=()

docker_methods+=(docker_build)
docker_methods+=(docker_service_check)
docker_methods+=(docker_exec)
docker_methods+=(docker_exec_sh)
docker_methods+=(docker_logs)
docker_methods+=(docker_pull)
docker_methods+=(docker_rm)
docker_methods+=(docker_rmi)
docker_methods+=(docker_run)
docker_methods+=(docker_start)
docker_methods+=(docker_status)
docker_methods+=(docker_stop)