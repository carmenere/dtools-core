function redis_user_admin() {
  REDIS_USER="default"
  REDIS_PASSWORD=''
}

function redis_db_0() {
  REDIS_DB=0
}

function redis_user_app() {
  REDIS_USER="dt_user"
  REDIS_PASSWORD="12345"
}

function ctx_conn_redis_admin() {
  ctx_service_redis && \
  redis_db_0 && \
  redis_user_admin
}

function ctx_conn_redis_app() {
  ctx_service_redis && \
  redis_db_0 && \
  redis_user_app
}

function ctx_conn_docker_redis_admin() {
  ctx_docker_redis && \
  redis_db_0 && \
  redis_user_admin
}

function ctx_conn_docker_redis_app() {
  ctx_docker_redis && \
  redis_db_0 && \
  redis_user_app
}
