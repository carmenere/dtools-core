function clickhouse_user_admin() {
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_USER="dt_admin"
}

function clickhouse_db_default() {
  CLICKHOUSE_DB="default"
}

function clickhouse_db_example() {
  CLICKHOUSE_DB="example"
}

function clickhouse_user_app() {
  CLICKHOUSE_PASSWORD="12345"
  CLICKHOUSE_USER="example"
}

function ctx_conn_clickhouse_admin() {
  ctx_service_clickhouse && \
  clickhouse_db_default && \
  clickhouse_user_admin
}

function ctx_conn_clickhouse_app() {
  ctx_service_clickhouse && \
  clickhouse_db_example && \
  clickhouse_user_app
}

function ctx_conn_docker_clickhouse_admin() {
  ctx_docker_clickhouse && \
  clickhouse_db_default && \
  clickhouse_user_admin
}

function ctx_conn_docker_clickhouse_app() {
  ctx_docker_clickhouse && \
  clickhouse_db_example && \
  clickhouse_user_app
}
