# ctx_service_redis && redis_install
function redis_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec ${fname} "${SUDO} apt install lsb-release curl gpg"
    dt_exec ${fname} "curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg" || return $?
    dt_exec ${fname} "echo 'deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main' | ${SUDO} tee /etc/apt/sources.list.d/redis.list" || return $?
    dt_exec ${fname} "${SUDO} apt-get update" || return $?
    dt_exec ${fname} "${SUDO} apt-get -y install redis" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec ${fname} "brew install $(redis_service)"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    SERVICE="redis"
  else
    SERVICE="redis-server"
  fi
  STOP_CMD="$(os_service) stop '${SERVICE}'"
  START_CMD="$(os_service) start '${SERVICE}'"
  PREPARE_CMD=
  INSTALL_CMD=redis_install
  LSOF=lsof_redis
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
  redis_service
}

dt_register "ctx_service_redis" "redis" "$(service_methods)"

function lsof_redis() {
  HOST=${REDIS_HOST}
  PORT=${REDIS_PORT}
  lsof_tcp
}
