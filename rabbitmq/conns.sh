ctx_socket_rmq() {
  if [ "${PROFILE_RMQ}" = "docker" ]; then
    ctx_docker_rmq
  else
    ctx_service_rmq
  fi
}

function ctx_account_admin_rmq() {
  RABBIT_USER="guest"
  RABBIT_PASSWORD="guest"
}

function ctx_account_app_rmq() {
  RABBIT_USER="app_user"
  RABBIT_PASSWORD=12345
}