#  FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]

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

docker_build_args() { echo "$(inline_vars "$(BUILD_ARGS)" --build-arg)"; }
docker_run_publish() { echo "$(inline_vals "$(PUBLISH)" --publish)"; }
docker_run_envs() { echo "$(inline_vars "$(RUN_ENVS)" --env)"; }

docker_build() { exec_cmd docker build $(docker_build_args) -t $(IMAGE) -f "$(DOCKERFILE)" "$(CTX)"; }
docker_exec() { echo "docker exec -i $(CONTAINER)"; }
docker_exec_sh() { exec_cmd "docker exec -ti $(CONTAINER) /bin/sh"; }
docker_logs() { exec_cmd docker logs "$(CONTAINER)"; }
docker_logs_save_to_logfile() { exec_cmd docker logs "$(CONTAINER)" '>' "${DT_LOGS}/container-$(CONTAINER).log" '2>&1'; }
docker_network_create() { exec_cmd docker network create --driver=$(DRIVER) --subnet=$(SUBNET) $(BRIDGE); }
docker_network_rm() { exec_cmd docker network rm $(BRIDGE); }
docker_pull() { exec_cmd docker pull $(IMAGE); }
docker_rm() { exec_cmd docker rm --force $(CONTAINER); }
docker_rmi() { exec_cmd docker rmi $(IMAGE); }
docker_start() { exec_cmd docker start $(CONTAINER); }
docker_status() { exec_cmd docker ps -a --filter name="^$(CONTAINER)$"; }
docker_stop() { exec_cmd docker stop $(CONTAINER); }

function docker_network_create() {
  local id fname=$(fname "${FUNCNAME[0]}" "$0")
  id="$(exec_cmd "docker network ls -q --filter name="^$(BRIDGE)$"")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Bridge ${BOLD}$(BRIDGE)${RESET} with id='${id}' exists, skip create."
    return 0
  fi
  if [ -z "$(BRIDGE)" ]; then dt_error ${fname} "Parameter BRIDGE is empty. Cannot create bridge."; return 99; fi
  exec_cmd docker network create --driver=$(DRIVER) --subnet=$(SUBNET) $(BRIDGE)
}

docker_run() {
  local id fname=$(fname "${FUNCNAME[0]}" "$0")
  docker_network_create || return $?
  id="$(exec_cmd "docker ps -aq --filter name="^$(CONTAINER)$" --filter status=running")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}$(CONTAINER)${RESET} with id='${id}' is running, skip run."
    return 0
  fi
  id="$(exec_cmd "docker ps -aq --filter name="^$(CONTAINER)$" --filter status=exited --filter status=created")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}$(CONTAINER)${RESET} with id='${id}' was created but is stopped now, so start it."
    exec_cmd docker start $(CONTAINER) || return $?
    return 0
  fi
  exec_cmd docker run $(FLAGS) --name $(CONTAINER) $(docker_run_envs) $(docker_run_publish) --restart $(RESTART) \
      --network $(BRIDGE) $(IMAGE) "$(COMMAND)"
}

docker_check() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "$(SERVICE_CHECK)" ]; then dt_error ${fname} "Variable ${BOLD}SERVICE_CHECK${RESET} is empty"; return 99; fi
  for i in $(seq 1 30); do
    dt_info ${fname} "Waiting ${BOLD}$(CONTAINER)${RESET} runtime: attempt ${BOLD}$i${RESET} ... ";
    if docker_exec_cmd "$(SERVICE_CHECK)"; then
      dt_info ${fname} "Container ${BOLD}$(CONTAINER)${RESET} is up now"
      break
    fi
    sleep 1
  done
}

# Don't depend on Vars
docker_ps() { docker ps -a; }
docker_network_ls() { exec_cmd docker network ls; }
docker_is_running() { if ! docker ps 1>/dev/null; then error $0 "${BOLD}Dockerd is not run!${RESET}"; return 99; fi; }

docker_rm_all() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
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

function docker_methods() {
  local methods=()
  methods+=(docker_build)
  methods+=(docker_check)
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
  var IMAGE $(BASE_IMAGE)
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
