# FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]
add_run_env() {
  run_envs["$1"]="$2"
  RUN_ENVS+=("$1")
}

add_build_args() {
  build_args["$1"]="$2"
  BUILD_ARGS+=("$1")
}

add_publish() { if [ -z "${PUBLISH}" ]; then PUBLISH="--publish"; fi; PUBLISH="${PUBLISH} $1"; }

ser_build_args() {
  local result var val fname=ser_build_args
  result=()
  for var in ${BUILD_ARGS[@]}; do
    val=${build_args["${var}"]}
    dt_debug ${fname} "var=${var}; val=${val}"
    val=$(ser_val "${val}")
    result+=("--build-arg ${var}=${val}")
  done
  echo "${result[@]}"
}

ser_run_envs() {
  local result var val fname=ser_run_envs
  result=()
  for var in ${RUN_ENVS[@]}; do
    val=${run_envs["${var}"]}
    dt_debug ${fname} "var=${var}; val=${val}"
    val=$(ser_val "${val}")
    result+=("--env ${var}=${val}")
  done
  echo "${result[@]}"
}

docker_install() {
  SUDO=sudo
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "${SUDO} apt-get update"
    exec_cmd "${SUDO} apt-get install -y ca-certificates curl gnupg"
    exec_cmd "${SUDO} install -m 0755 -d /etc/apt/keyrings"
    exec_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg"
    exec_cmd "${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg"
    exec_cmd "echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "${VERSION_CODENAME}")" stable" | \
      ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null"
    exec_cmd "${SUDO} apt-get update"
    exec_cmd "${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

# post-install actions
docker_post_install() {
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      ${SUDO} groupadd docker || true
      ${SUDO} usermod -aG docker ${USER}
  fi
}

docker_arm64v8() {
  if [ "$(uname -m)" = "arm64" ]; then
    echo "arm64v8/"
  fi
}

docker_default_tag() {
  local tag=v0.0.1
  if [ -n "$1" ]; then tag=$1; fi
  if [ "$(uname -m)" = "arm64" ]; then
    echo "${tag}-arm64"
  else
    echo "${tag}"
  fi
}

DOCKER_IMAGES=${DT_VARS}/docker_images
DOCKER_BRIDGES=${DT_VARS}/docker_bridges
DOCKER_SERVICES=${DT_VARS}/docker_services

# DOCKER_BRIDGES
docker_network_create() {(
  set -eu
  local id fname=docker_network_create
  . "${DOCKER_BRIDGES}/$1.sh"
  id="$(exec_cmd "docker network ls -q --filter name="^${BRIDGE}$"")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Bridge ${BOLD}${BRIDGE}${RESET} with id='${id}' exists, skip create."
    return 0
  fi
  if [ -z "${BRIDGE}" ]; then dt_error ${fname} "Parameter BRIDGE is empty. Cannot create bridge."; return 99; fi
  exec_cmd docker network create --driver=${DRIVER} --subnet=${SUBNET} ${BRIDGE}
)}
docker_network_rm() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker network rm ${BRIDGE} )}

# DOCKER_IMAGES
docker_pull() {( set -eu; . "${DOCKER_IMAGES}/$1.sh" && exec_cmd docker pull ${IMAGE} )}
docker_rmi() {( set -eu; . "${DOCKER_IMAGES}/$1.sh" && exec_cmd docker rmi ${IMAGE} )}
docker_build() {(
  set -eu; . "${DOCKER_IMAGES}/$1.sh"
  exec_cmd docker build $(ser_build_args) -t ${IMAGE} -f "${DOCKERFILE}" "${CTX}"
)}

# DOCKER_SERVICES
docker_check() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && service_check )}
docker_exec_i() {(
  set -eu; . "${DOCKER_SERVICES}/$1.sh"
  shift
  exec_cmd "docker exec -i ${SERVICE} /bin/sh << EOF\n$@\nEOF"
)}
docker_exec_it() {(
  set -eu; . "${DOCKER_SERVICES}/$1.sh"
  shift
  exec_cmd "docker exec -ti ${SERVICE} /bin/sh -c \"$@\""
)}
docker_exec_sh() { docker_exec_it $1 }
docker_logs() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker logs "${SERVICE}" )}
docker_logs_save_to_logfile() {(
  set -eu; . "${DOCKER_SERVICES}/$1.sh"
  exec_cmd docker logs "${SERVICE}" '>' "${DT_LOGS}/container-${SERVICE}.log" '2>&1'
)}
docker_rm() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker rm --force ${SERVICE} )}
docker_start() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker start ${SERVICE} )}
docker_status() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker ps -a --filter name="^${SERVICE}$" )}
docker_stop() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd docker stop ${SERVICE} )}
docker_ps() {( set -eu; . "${DOCKER_SERVICES}/$1.sh" && exec_cmd "docker ps -a --filter name="^${SERVICE}$"" )}
docker_run() {(
  set -eu
  local id fname=docker_run
  . "${DOCKER_SERVICES}/$1.sh" || return $?
  docker_network_create ${BRIDGE} || return $?
  id="$(exec_cmd "docker ps -aq --filter name="^${SERVICE}$" --filter status=running")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${SERVICE}${RESET} with id='${id}' is running, skip run."
    return 0
  fi
  id="$(exec_cmd "docker ps -aq --filter name="^${SERVICE}$" --filter status=exited --filter status=created")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}${SERVICE}${RESET} with id='${id}' was created but is stopped now, so start it."
    exec_cmd docker start ${SERVICE} || return $?
    return 0
  fi
  exec_cmd docker run ${FLAGS} --name ${SERVICE} $(ser_run_envs) ${PUBLISH} ${RM} --restart ${RESTART} \
      --network ${BRIDGE} ${IMAGE} "${COMMAND}"
)}

# Don't depend on Vars
docker_ps_all() { docker ps -a; }
docker_network_ls() { exec_cmd docker network ls; }
docker_is_running() { if ! docker ps 1>/dev/null; then error $0 "${BOLD}Dockerd is not run!${RESET}"; return 99; fi; }

docker_rm_all() {
  local fname=docker_rm_all
  if [ -z "$(exec_cmd docker ps -lq)" ]; then dt_info ${fname} "docker_rm_all: nothing to delete."; return 0; fi
  exec_cmd docker rm --force $(docker ps -aq)
}

docker_prune() {
  docker_rm_all
  exec_cmd "docker system prune --force"
  exec_cmd "docker volume prune --force"
  exec_cmd "docker network prune --force"
}

docker_purge() {
  docker_rm_all
  exec_cmd "docker system prune --force --all --volumes"
  exec_cmd "docker volume prune --force"
  exec_cmd "docker network prune --force"
  exec_cmd "docker builder prune --force --all"
}

##################################################### AUTOCOMPLETE #####################################################
methods_docker_service() {
  local methods=()
  methods+=(docker_check)
  methods+=(docker_exec_i)
  methods+=(docker_exec_it)
  methods+=(docker_exec_sh)
  methods+=(docker_logs)
  methods+=(docker_ps)
  methods+=(docker_rm)
  methods+=(docker_run)
  methods+=(docker_start)
  methods+=(docker_status)
  methods+=(docker_stop)
  echo "${methods[@]}"
}

methods_docker_network() {
  local methods=()
  methods+=(docker_network_create)
  methods+=(docker_network_rm)
  methods+=(docker_network_ls)
  echo "${methods[@]}"
}

methods_docker_image() {
  local methods=()
  methods+=(docker_build)
  methods+=(docker_rmi)
  methods+=(docker_pull)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_docker_network)
DT_AUTOCOMPLETE+=(methods_docker_service)
DT_AUTOCOMPLETE+=(methods_docker_image)

DT_AUTOCOMPLETIONS["methods_docker_network"]=""
DT_AUTOCOMPLETIONS["methods_docker_service"]=""
DT_AUTOCOMPLETIONS["methods_docker_image"]=""