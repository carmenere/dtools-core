redis_account=(REDIS_USER REDIS_DB REDIS_PASSWORD)

function redis_account_vars() {
  echo "${redis_account[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
}

function ctx_redis_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(redis_account_vars)
  REDIS_USER="default"
  REDIS_PASSWORD="1234567890"
  REDIS_DB=0
  dt_set_ctx -c ${ctx}
}

function ctx_redis_app() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(redis_account_vars)
  REDIS_USER="example_app"
  REDIS_PASSWORD="1234567890"
  REDIS_DB=0
  dt_set_ctx -c ${ctx}
}
