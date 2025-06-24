# PROFILE_REDIS={ host | docker }, by default "host"
if [ -z "${PROFILE_REDIS}" ]; then export PROFILE_REDIS="host"; fi

function redis_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "redis"
  else
    echo "redis-server"
  fi
}

# ctx_host_redis && redis_install
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

function ctx_host_redis() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_HOST "localhost" && \
  var MAJOR 7 && \
  var MINOR 2 && \
  var PATCH 4 && \
  var REDIS_PORT 6379 && \
  var SERVICE $(redis_service) && \
  var SERVICE_CHECK_CMD "sh -c 'redis-cli ping 1>/dev/null 2>&1'" && \
  var SERVICE_INSTALL redis_install && \
  var SERVICE_LSOF lsof_redis && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_host_redis:redis:service_methods)
