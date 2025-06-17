#  FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]

docker_install() {
  SUDO=sudo
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    cmd_exec "${SUDO} apt-get update"
    cmd_exec "${SUDO} apt-get install -y ca-certificates curl gnupg"
    cmd_exec "${SUDO} install -m 0755 -d /etc/apt/keyrings"
    cmd_exec "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg"
    cmd_exec "${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg"
    cmd_exec "echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "${VERSION_CODENAME}")" stable" | \
      ${SUDO} tee /etc/apt/sources.list.d/docker.list > /dev/null"
    cmd_exec "${SUDO} apt-get update"
    cmd_exec "${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

docker_post_install() {
  # post-install actions
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
  if [ "$(uname -m)" = "arm64" ]; then
    echo "v0.0.1-arm64"
  else
    echo "v0.0.1"
  fi
}

docker_build_args() { echo "$(inline_vars "${BUILD_ARGS}" --build-arg)"; }
docker_run_publish() { echo "$(inline_vals "${PUBLISH}" --publish)"; }
docker_run_envs() { echo "$(inline_vars "${RUN_ENVS}" --env)"; }

docker_build() { cmd_exec docker build $(docker_build_args) -t ${IMAGE} -f "${DOCKERFILE}" "${CTX}"; }
docker_exec() { echo "docker cmd_exec -ti ${CONTAINER}"; }
docker_exec_sh() { cmd_exec "docker cmd_exec -ti ${CONTAINER} /bin/sh"; }
docker_logs() { cmd_exec docker logs "${CONTAINER}"; }
docker_logs_save_to_logfile() { cmd_exec docker logs "${CONTAINER}" '>' "${DT_LOGS}/container-${CONTAINER}.log" '2>&1'; }
docker_network_create() { cmd_exec docker network create --driver=${DRIVER} --subnet=${SUBNET} ${BRIDGE}; }
docker_network_rm() { cmd_exec docker network rm ${BRIDGE}; }
docker_pull() { cmd_exec docker pull ${IMAGE}; }
docker_rm() { cmd_exec docker rm --force ${CONTAINER}; }
docker_rmi() { cmd_exec docker rmi ${IMAGE}; }
docker_run() { cmd_exec docker run ${FLAGS} --name ${CONTAINER} $(docker_run_envs) $(docker_run_publish) \
    --restart ${RESTART} --network ${BRIDGE} ${IMAGE} "${COMMAND}"; }
docker_start() { cmd_exec docker start ${CONTAINER}; }
docker_status() { cmd_exec docker ps -a --filter name="^${CONTAINER}$"; }
docker_stop() { cmd_exec docker stop ${CONTAINER}; }

docker_service_check() {
  local cmd="$(docker_exec) ${CHECK_CMD}"
  for i in $(seq 1 30); do
    dt_info "${BOLD}Waiting ${CONTAINER} runtime${RESET}: attempt ${BOLD}$i${RESET} ... ";
    if cmd_exec ${cmd}; then dt_info "${BOLD}${CONTAINER}${RESET} is up now"; break; fi
    sleep 1
  done
}

# Don't depend on Vars
docker_ps() { docker ps -a; }
docker_network_ls() { cmd_exec docker network ls; }
docker_is_running() { if ! docker ps 1>/dev/null; then error $0 "${BOLD}Dockerd is not run!${RESET}"; return 99; fi; }

docker_rm_all() {
  if [ -z "$(cmd_exec docker ps -lq)" ]; then dt_info "docker_rm_all(): nothing to delete."; return 0; fi
  cmd_exec docker rm --force $(docker ps -aq)
}

docker_prune() {
  docker_rm_all
  cmd_exec "docker system prune --force"
  cmd_exec "docker volume prune --force"
  cmd_exec "docker network prune --force"
}

docker_purge() {
  docker_rm_all
  cmd_exec "docker system prune --force --all --volumes"
  cmd_exec "docker volume prune --force"
  cmd_exec "docker network prune --force"
  cmd_exec "docker builder prune --force --all"
}

function docker_methods() {
  local methods=()
  methods+=(docker_build)
  methods+=(docker_service_check)
  methods+=(docker_exec)
  methods+=(docker_exec_sh)
  methods+=(docker_logs)
  methods+=(docker_pull)
  methods+=(docker_rm)
  methods+=(docker_rmi)
  methods+=(docker_run)
  methods+=(docker_start)
  methods+=(docker_status)
  methods+=(docker_stop)
  echo "${methods[@]}"
}

function docker_network_methods() {
  local methods=()
  methods+=(docker_network_create)
  methods+=(docker_network_rm)
  methods+=(docker_network_ls)
  echo "${methods[@]}"
}

#  IMAGE="pg:${DEFAULT_TAG}"
#  BUILDER=${BUILDER_IMAGE}
#  BUILD_VERSION="$(git_build_version)"

ctx_docker_service() {
  var BASE_IMAGE
  var COMMAND
  var CONTAINER
  var CTX "."
  var FLAGS "-d"
  var IMAGE ${BASE_IMAGE}
  var RESTART "always"
  var RM
  var SH "/bin/sh"
}

ctx_docker_network() {
  var SUBNET "192.168.111.0/24"
  var BRIDGE "example"
  var DRIVER "bridge"
}

DT_BINDINGS+=(ctx_docker_network:example:docker_network_methods)
