function rabbitmq_user_admin() {
  RABBIT_USER="guest"
  RABBIT_PASSWORD="guest"
}

function rabbitmq_user_app() {
  RABBIT_USER="app_user"
  RABBIT_PASSWORD=12345
}

function ctx_conn_rabbitmq_admin() {
  ctx_service_rabbitmq && \
  rabbitmq_user_admin
}

function ctx_conn_rabbitmq_app() {
  ctx_service_rabbitmq && \
  rabbitmq_user_app
}

function ctx_conn_docker_rabbitmq_admin() {
  ctx_docker_rabbitmq && \
  rabbitmq_user_admin
}

function ctx_conn_docker_rabbitmq_app() {
  ctx_docker_rabbitmq && \
  rabbitmq_user_app
}
