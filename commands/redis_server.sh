function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "redis"
  else
    echo "redis-server"
  fi
}

# ctx_host_redis && install_redis
function install_redis() {(
  local fname=install_redis
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "${SUDO} apt install lsb-release curl gpg"
    exec_cmd "curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg" || return $?
    exec_cmd "echo 'deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main' | ${SUDO} tee /etc/apt/sources.list.d/redis.list" || return $?
    exec_cmd "${SUDO} apt-get update" || return $?
    exec_cmd "${SUDO} apt-get -y install redis" || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(redis_service)"

  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_redis_services() {
  local methods=()
  methods+=(install_redis)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_redis_services"