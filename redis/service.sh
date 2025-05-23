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

  _export_envs=(
    REDIS_HOST
    MAJOR
    MINOR
    PATCH
    REDIS_PORT
    REQUIREPASS
  )
}

function service_stop_redis() {
  (
    local mode=$1
    ctx_service_redis && dt_exec_or_echo "$(service) stop '$(redis_service)'" $mode
  )
}

function service_start_redis() {
  (
    local mode=$1
    ctx_service_redis && dt_exec_or_echo "$(service) start '$(redis_service)'" $mode
  )
}

function service_restart_redis() {
  service_stop_redis && service_start_redis
}

function lsof_redis() {
  (
    ctx_service_redis; exit_on_err $0 $? || return $?
    HOST=${REDIS_HOST}
    PORT=${REDIS_PORT}
    lsof_tcp
  )
}