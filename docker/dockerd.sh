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

function docker_is_running() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if ! docker ps 1>/dev/null; then dt_error ${fname} "${BOLD}Service docker is not run!${RESET}"; return 99; fi
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

