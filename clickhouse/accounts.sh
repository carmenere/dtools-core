clickhouse_account=(CLICKHOUSE_USER CLICKHOUSE_DB CLICKHOUSE_PASSWORD)
clickhouse_account_vars=(CLICKHOUSE_USER CLICKHOUSE_DB CLICKHOUSE_PASSWORD ${dt_vars[@]})

function ctx_clickhouse_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${clickhouse_account_vars}")
  CLICKHOUSE_USER="dt_admin"
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_DB="default"
  dt_set_ctx -c ${ctx}
}

function ctx_clickhouse_app() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=("${clickhouse_account_vars}")
  CLICKHOUSE_USER="example_app"
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_DB="example"
  dt_set_ctx -c ${ctx}
}

function ctx_docker_clickhouse_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  dt_load_vars -c ctx_clickhouse_admin || return $?
  CLICKHOUSE_USER="default"
  dt_set_ctx -c ${ctx}
}
