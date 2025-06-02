function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "redis"
  else
    echo "redis-server"
  fi
}

# ctx_service_redis && redis_install
function redis_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec "${SUDO} apt install lsb-release curl gpg"
    dt_exec "curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg"; exit_on_err ${fname} $? || return $?
    dt_exec "echo 'deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main' | ${SUDO} tee /etc/apt/sources.list.d/redis.list"; exit_on_err ${fname} $? || return $?
    dt_exec "${SUDO} apt-get update"; exit_on_err ${fname} $? || return $?
    dt_exec "${SUDO} apt-get -y install redis"; exit_on_err ${fname} $? || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec "brew install $(redis_service)"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
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
  SERVICE_PREPARE=
  SERVICE_INSTALL=redis_install
  SERVICE_LSOF=lsof_redis
}

function lsof_redis() {
  (
    HOST=${REDIS_HOST}
    PORT=${REDIS_PORT}
    lsof_tcp
  )
}

dt_register "ctx_service_redis" "redis" "${service_methods[@]}"
