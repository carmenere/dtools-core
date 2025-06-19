function redis_exec() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  open_ctx ${query_ctx} && query=$(${query}) || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  open_ctx ${conn_ctx} && conn="$(cmd_echo redis_conn)" || return $?
  cmd_exec "${conn} ${query}" && close_ctx
}

function redis_conn() {
  local cmd fname=$(fname "${FUNCNAME[0]}" "$0")
  cmd=("redis-cli -e -u")
  cmd+=("redis://$(REDIS_USER):$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB)")
  cmd_exec "${cmd[@]}"
}

function redis_set_requirepass() {
  redis_exec $1 $2 redis_ql_set_requirepass
}

function redis_check_user() { redis_exec $1 $2 redis_ql_check_user; }
function redis_create_user() { redis_exec $1 $2 redis_ql_create_user; }
function redis_drop_user() { redis_exec $1 $2 redis_ql_drop_user; }

function redis_config_rewrite() {
  local conn_ctx=$1
  open_ctx ${conn_ctx} && cmd_exec "$(cmd_echo redis_conn) CONFIG REWRITE" && close_ctx
}

function redis_flushall() {
  local conn_ctx=$1
  open_ctx ${conn_ctx} && cmd_exec "$(cmd_echo redis_conn) FLUSHALL" && close_ctx
}
