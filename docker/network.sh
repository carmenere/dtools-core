function ctx_docker_network() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  var $c SUBNET "192.168.111.0/24"
  var $c BRIDGE "example"
  var $c ERR_IF_BRIDGE_EXISTS "n"
  var $c DRIVER "bridge"
  dt_cache ${c}
}

function docker_network_create() {
  local fname cmd id
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  id="$(dt_exec ${fname} "docker network ls -q --filter name="^${BRIDGE}$"")"
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
  cmd=(docker network create)
  if [ -n "${DRIVER}" ]; then cmd+=(--driver=${DRIVER}); fi
  if [ -n "${SUBNET}" ]; then cmd+=(--subnet=${SUBNET}); fi
  cmd+=(${BRIDGE})
  dt_exec ${fname} ${cmd[@]}
}

function docker_network_rm() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  dt_exec ${fname} docker network rm ${BRIDGE}
}

function docker_network_ls() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  docker_is_running || return $?
  dt_exec ${fname} docker network ls
}

function docker_network_methods() {
  local methods=()
  methods+=(docker_network_create)
  methods+=(docker_network_rm)
  methods+=(docker_network_ls)
  echo "${methods}"
}

dt_register "ctx_docker_network" "example" "$(docker_network_methods)"