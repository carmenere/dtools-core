# FULL NAME: REGISTRY[:PORT]/[r|_]/NAMESPACE/REPO[:TAG]

merge_docker_publish() {
  mvar PUBLISH "$(PORT $(SOCK)):$(PORT $(SOCK_INNER))/tcp"
}

merge_docker_network() {
  mvar SUBNET "192.168.111.0/24"
  mvar BRIDGE "example"
  mvar DRIVER "bridge"
}

merge_docker_image() {
  mvar BASE_IMAGE "$(docker_arm64v8)alpine:3.22.1"
  mvar DOCKERFILE
  mvar BUILD_VERSION "$(git_build_version)"
  mvar CTX "."
  mvar DEFAULT_TAG $(docker_default_tag)
  mvar IMAGE $(BASE_IMAGE)
}

merge_docker_service() {
  local tbl_sockets=sockets tbl_networks=docker_networks tbl_images=docker_images
  mvar publish merge_docker_publish
  mref bridge "${tbl_networks}" "default"
  mref image "${tbl_images}" "default"
  mvar CHECK "docker_check"
  mvar COMMAND
  mvar EXEC "docker_exec_i_cmd"
  mvar FLAGS "-d"
  mvar PUBLISH
  mvar RESTART "always"
  mvar RM
  mvar RUN_ENVS
  mvar SERVICE
  mvar SH "/bin/sh"
  mvar TERMINAL "docker_exec_it_cmd"
  mvar BRIDGE $(BRIDGE $(bridge))
  mvar IMAGE $(IMAGE $(image))
  mref SOCK_INNER "${tbl_sockets}" "default"
  mref SOCK "${tbl_sockets}" "default"
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

_docker_build_args() { echo "$(inline_vars "$(BUILD_ARGS)" --build-arg)"; }
_docker_run_publish() { echo "$(inline_vals "$(PUBLISH)" --publish)"; }
_docker_run_envs() { echo "$(inline_vars "$(RUN_ENVS)" --env)"; }

docker_build() { exec_cmd docker build $(_docker_build_args) -t $(IMAGE) -f "$(DOCKERFILE)" "$(CTX)"; }
docker_check() { service_check; }
docker_exec_i_cmd() { exec_cmd "docker exec -i $(SERVICE) /bin/sh << EOF\n$@\nEOF"; }
docker_exec_it_cmd() { exec_cmd "docker exec -ti $(SERVICE) /bin/sh -c \"$@\""; }
docker_exec_sh() { exec_cmd "docker exec -ti $(SERVICE) /bin/sh"; }
docker_logs() { exec_cmd docker logs "$(SERVICE)"; }
docker_logs_save_to_logfile() { exec_cmd docker logs "$(SERVICE)" '>' "${DT_LOGS}/container-$(SERVICE).log" '2>&1'; }
docker_network_create() { exec_cmd docker network create --driver=$(DRIVER) --subnet=$(SUBNET) $(BRIDGE); }
docker_network_rm() { exec_cmd docker network rm $(BRIDGE); }
docker_pull() { exec_cmd docker pull $(IMAGE); }
docker_rm() { exec_cmd docker rm --force $(SERVICE); }
docker_rmi() { exec_cmd docker rmi $(IMAGE); }
docker_start() { exec_cmd docker start $(SERVICE); }
docker_status() { exec_cmd docker ps -a --filter name="^$(SERVICE)$"; }
docker_stop() { exec_cmd docker stop $(SERVICE); }

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
  id="$(exec_cmd "docker ps -aq --filter name="^$(SERVICE)$" --filter status=running")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}$(SERVICE)${RESET} with id='${id}' is running, skip run."
    return 0
  fi
  id="$(exec_cmd "docker ps -aq --filter name="^$(SERVICE)$" --filter status=exited --filter status=created")" || return $?
  if [ -n "${id}" ]; then
    dt_info ${fname} "Container ${BOLD}$(SERVICE)${RESET} with id='${id}' was created but it is stopped now, so just start it."
    exec_cmd docker start $(SERVICE) || return $?
    return 0
  fi
  exec_cmd docker run $(FLAGS) --name $(SERVICE) $(_docker_run_envs) $(_docker_run_publish) $(RM) --restart $(RESTART) \
      --network $(BRIDGE) $(IMAGE) "$(COMMAND)"
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

methods_docker_images() {
  local methods=()
  methods+=(docker_build)
  methods+=(docker_pull)
  methods+=(docker_rmi)
  echo "${methods[@]}"
}

function methods_docker_services() {
  local methods=()
  methods+=(docker_check)
  methods+=(docker_exec_i_cmd)
  methods+=(docker_exec_it_cmd)
  methods+=(docker_exec_sh)
  methods+=(docker_logs)
  methods+=(docker_rm)
  methods+=(docker_run)
  methods+=(docker_start)
  methods+=(docker_status)
  methods+=(docker_stop)
  echo "${methods[@]}"
}

function methods_docker_networks() {
  local methods=()
  methods+=(docker_network_create)
  methods+=(docker_network_rm)
  methods+=(docker_network_ls)
  echo "${methods[@]}"
}

