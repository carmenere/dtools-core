function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "redis"
  else
    echo "redis-server"
  fi
}

function redis_install() {
  SUDO=$(dt_sudo)
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    ${SUDO} apt install lsb-release curl gpg
    curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg; exit_on_err $0 $? || return $?
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main" | ${SUDO} tee /etc/apt/sources.list.d/redis.list; exit_on_err $0 $? || return $?
    ${SUDO} apt-get update; exit_on_err $0 $? || return $?
    ${SUDO} apt-get -y install redis; exit_on_err $0 $? || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    brew install "redis@${MAJOR}"

  else
    echo "Unsupported OS: '$(os_kernel)'"; exit;
  fi
}

function ctx_service_redis() {
  CONFIG_REWRITE="y"
  ERR_IF_USER_EXISTS="n"
  REDIS_HOST="localhost"
  MAJOR=7
  MINOR=2
  PATCH=4
  REDIS_PORT=6379
  REQUIREPASS="y"
  SERVICE_STOP="$(service) stop '$(redis_service)'"
  SERVICE_START="$(service) start '$(redis_service)'"
}

function lsof_redis() {
  (
    ctx_service_redis; exit_on_err $0 $? || return $?
    HOST=${REDIS_HOST}
    PORT=${REDIS_PORT}
    lsof_tcp
  )
}

dt_register "ctx_service_redis" "redis" "${service_methods[@]}"
