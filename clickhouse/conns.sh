clickhouse_connurl() {
  local vars=(CLICKHOUSE_DB CLICKHOUSE_HOST CLICKHOUSE_PASSWORD CLICKHOUSE_PORT PGUSER)
  echo "${vars}"
}

ctx_conn_clickhouse() {
  if [ "${PROFILE_CLICKHOUSE}" = "docker" ]; then
    ctx_docker_clickhouse
  else
    ctx_service_clickhouse
  fi
}

ctx_conn_admin_clickhouse() {
  var CLICKHOUSE_USER "dt_admin"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "default"
}

ctx_conn_app_clickhouse() {
  var CLICKHOUSE_USER "example_app"
  var CLICKHOUSE_PASSWORD "1234567890"
  var CLICKHOUSE_DB "example"
}

