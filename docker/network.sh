docker_network_vars=(SUBNET BRIDGE ERR_IF_BRIDGE_EXISTS DRIVER ${dt_vars[@]})

function ctx_docker_network() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${docker_network_vars}")
  SUBNET="192.168.111.0/24"
  BRIDGE="example"
  ERR_IF_BRIDGE_EXISTS="n"
  DRIVER="bridge"
  dt_set_ctx -c ${ctx}
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
