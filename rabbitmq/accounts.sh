rmq_account=( RABBIT_USER RABBIT_PASSWORD )

function rmq_account_vars() {
  echo "${rmq_account[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
}

function ctx_rabbitmq_admin() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(rmq_account_vars)
  RABBIT_USER="guest"
  RABBIT_PASSWORD="guest"
  dt_set_ctx -c ${ctx}
}

function ctx_rabbitmq_app() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(rmq_account_vars)
  RABBIT_USER="app_user"
  RABBIT_PASSWORD=12345
  dt_set_ctx -c ${ctx}
}
