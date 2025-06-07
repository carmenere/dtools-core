clickhouse_account=(CLICKHOUSE_USER CLICKHOUSE_DB CLICKHOUSE_PASSWORD)

function clickhouse_account_vars() {
  echo "${clickhouse_account[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
}

function ctx_clickhouse_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(clickhouse_account_vars)
  CLICKHOUSE_USER="dt_admin"
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_DB="default"
  dt_set_ctx -c ${ctx}
}

function ctx_clickhouse_app() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(clickhouse_account_vars)
  CLICKHOUSE_USER="example_app"
  CLICKHOUSE_PASSWORD="1234567890"
  CLICKHOUSE_DB="example"
  dt_set_ctx -c ${ctx}
}
