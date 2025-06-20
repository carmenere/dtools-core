# PROFILE_REDIS={ host | docker }, by default "host"
if [ -z "${PROFILE_REDIS}" ]; then export PROFILE_REDIS="host"; fi

select_service_redis() {
  if [ "${PROFILE_REDIS}" = "docker" ]; then echo "ctx_docker_redis"; else echo "ctx_service_redis"; fi
}

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
    exec_cmd "${SUDO} apt install lsb-release curl gpg"
    exec_cmd "curl -fsSL https://packages.redis.io/gpg | ${SUDO} gpg --batch --yes --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg" || return $?
    exec_cmd "echo 'deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(os_codename) main' | ${SUDO} tee /etc/apt/sources.list.d/redis.list" || return $?
    exec_cmd "${SUDO} apt-get update" || return $?
    exec_cmd "${SUDO} apt-get -y install redis" || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(redis_service)"

  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function lsof_redis() {
  HOST=$(REDIS_HOST); PORT=$(REDIS_PORT)
  lsof_tcp
}

function ctx_service_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var REDIS_HOST "localhost"
  var MAJOR 7
  var MINOR 2
  var PATCH 4
  var REDIS_PORT 6379
  var SERVICE $(redis_service)
  var SERVICE_CHECK "sh -c 'redis-cli ping 1>/dev/null 2>&1'"
  var SERVICE_INSTALL redis_install
  var SERVICE_LSOF lsof_redis
  ctx_os_service && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_service_redis:redis:service_methods)
