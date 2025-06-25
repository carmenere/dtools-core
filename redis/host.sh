# REDIS_MODE={ host | docker }, by default "host"
# Exported to be seen in child process, if set in parent - do not change.
if [ -z "${REDIS_MODE}" ]; then export REDIS_MODE="host"; fi

redis_mode() {
  if [ "${REDIS_MODE}" = "docker" ]; then
    echo "docker"
  elif [ "${REDIS_MODE}" = "host" ]; then
    echo "host"
  else
    dt_error ${fname} "Unknown redis mode: REDIS_MODE=${REDIS_MODE}"
    return 99
  fi
}

set_redis_mode_docker() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  REDIS_MODE=docker
  if is_var_changed REDIS_MODE; then drop_vars; fi && \
  dt_info ${fname} "REDIS_MODE=${REDIS_MODE}"
}

set_redis_mode_host() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  REDIS_MODE=host
  if is_var_changed REDIS_MODE; then drop_vars; fi && \
  dt_info ${fname} "REDIS_MODE=${REDIS_MODE}"
}

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

function ctx_redis_host() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var REDIS_HOST "localhost" && \
  var MAJOR 7 && \
  var MINOR 2 && \
  var PATCH 4 && \
  var REDIS_PORT 6379 && \
  var SERVICE $(redis_service) && \
  var SERVICE_CHECK_CMD "redis_conn_admin -c $'ping'" && \
  var SERVICE_INSTALL redis_install && \
  var SERVICE_LSOF lsof_redis && \
  var CLIENT redis-cli && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_redis_host:redis:service_methods)
