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
  CHECK_CMD=
  # Hooks
  hook_pre_docker_run=
  docker_run_envs=()
}

function docker_exec() {
  echo "docker exec -ti ${CONTAINER}"
}

function docker_exec_sh() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  dt_exec ${fname} "docker exec -ti ${CONTAINER} /bin/sh"
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
  PUBLISH=($(echo ${PUBLISH}))
  for publish in ${PUBLISH[@]}; do
    cmd+=(--publish "${publish}")
  done
}

function _docker_run_env_opts() {
  docker_run_envs=($(echo ${docker_run_envs}))
  for e in "${docker_run_envs[@]}"; do
    if [ -z "$e" ]; then continue; fi
    val=$(dt_escape_quote "$(eval echo "\$$e")")
    if [ -n "${val}" ]; then cmd+=(--env "${e}=$'${val}'"); fi
  done
}

function docker_run() {
  local fname cmd id
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  docker_network_create || return $?
  id="$(dt_exec ${fname} "docker ps -aq --filter name="^${CONTAINER}$" --filter status=running")"
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${CONTAINER}${RESET} with id='${id}' is running, skip run."
    return 0
  fi
  id="$(dt_exec ${fname} "docker ps -aq --filter name="^${CONTAINER}$" --filter status=exited --filter status=created")"
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${CONTAINER}${RESET} with id='${id}' was created but is stopped now, so start it."
    cmd=(docker start ${CONTAINER})
    dt_exec ${fname} "${cmd[@]}"
    return 0
  fi
  cmd=(docker run)

  $hook_pre_docker_run && \
  _docker_run_publish_opts && \
  _docker_run_env_opts && \
  _docker_run_opts && \
  dt_exec ${fname} "${cmd[@]}"
}

function docker_start() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker start ${CONTAINER})
  dt_exec ${fname} "${cmd[@]}"
}

function docker_stop() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker stop ${CONTAINER})
  dt_exec ${fname} "${cmd[@]}"
}

function docker_rm() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker rm --force ${CONTAINER})
  dt_exec ${fname} "${cmd[@]}"
}

function docker_rm_all() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  if [ -z "$(dt_exec ${fname} "docker ps -lq")" ]; then dt_info ${fname} "docker_rm_all(): nothing to delete."; return 0; fi
  cmd=(docker rm --force $(docker ps -aq))
  dt_exec ${fname} "${cmd[@]}"
}

function docker_status() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker ps -a --filter name="^${CONTAINER}$")
  dt_exec ${fname} "${cmd[@]}"
}

function docker_logs() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker logs "${CONTAINER}")
  dt_exec ${fname} "${cmd[@]}"
}

function docker_logs_save_to_logfile() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  cmd=(docker logs "${CONTAINER}" '>' "${DT_LOGS}/container-${CONTAINER}.log" '2>&1')
  dt_exec ${fname} "${cmd[@]}"
}

function docker_service_check() {
  local fname cmd container
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cmd="$(docker_exec) ${CHECK_CMD}"
  container=${CONTAINER}
  for i in $(seq 1 30); do
    dt_info ${fname} "${BOLD}Waiting ${container} runtime${RESET}: attempt ${BOLD}$i${RESET} ... ";
    if dt_exec ${fname} ${cmd}; then dt_info ${fname} "${BOLD}${container}${RESET} is up now"; break; fi
    sleep 1
  done
}
