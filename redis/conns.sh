ctx_socket_redis() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ "${PROFILE_REDIS}" = "docker" ]; then
    ctx_docker_redis || return $?
  else
    ctx_service_redis || return $?
  fi
}

function ctx_account_admin_redis() {
  REDIS_USER="default"
  REDIS_PASSWORD="1234567890"
  REDIS_DB=0
}

function ctx_account_app_redis() {
  REDIS_USER="example_app"
  REDIS_PASSWORD="1234567890"
  REDIS_DB=0
}
