PROFILE_REDIS="host"

function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "redis"
  else
    echo "redis-server"
  fi
}

# ctx_service_redis && redis_install
function redis_install() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    cmd_exec "${SUDO} apt install lsb-release curl gpg"
    cmd_exec "curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg" || return $?
    cmd_exec "echo 'deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main' | ${SUDO} tee /etc/apt/sources.list.d/redis.list" || return $?
    cmd_exec "${SUDO} apt-get update" || return $?
    cmd_exec "${SUDO} apt-get -y install redis" || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    cmd_exec "brew install $(redis_service)"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function ctx_service_redis() {
  var REDIS_HOST "localhost"
  var MAJOR 7
  var MINOR 2
  var PATCH 4
  var REDIS_PORT 6379
  var SERVICE $(redis_service)
  var SERVICE_INSTALL redis_install
  var SERVICE_LSOF lsof_redis
  ctx_os_service || return $?
}

function lsof_redis() {(
  HOST=${REDIS_HOST}; PORT=${REDIS_PORT}
  lsof_tcp
)}

DT_BINDINGS+=(ctx_service_redis:redis:service_methods)
