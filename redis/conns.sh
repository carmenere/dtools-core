ctx_socket_redis() {
  if [ "${PROFILE_REDIS}" = "docker" ]; then
    ctx_docker_redis
  else
    ctx_service_redis
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
