function redis_exec() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx query" || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  push_ctx ${query_ctx} && query=$(${query}) || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  push_ctx ${conn_ctx} && conn="$(cmd_echo redis_conn)" || return $?
  exec_cmd "${conn} ${query}" && pop_ctx
}

function redis_conn() {
  local cmd fname=$(fname "${FUNCNAME[0]}" "$0")
  cmd=("redis-cli -e -u")
  cmd+=("redis://$(REDIS_USER):$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB)")
  exec_cmd "${cmd[@]}"
}

function redis_set_requirepass() {
  redis_exec $1 $2 redis_ql_set_requirepass
}

function redis_check_user() { redis_exec $1 $2 redis_ql_check_user; }
function redis_create_user() { redis_exec $1 $2 redis_ql_create_user; }
function redis_drop_user() { redis_exec $1 $2 redis_ql_drop_user; }

function redis_config_rewrite() {
  local conn_ctx=$1
  push_ctx ${conn_ctx} && exec_cmd "$(cmd_echo redis_conn) CONFIG REWRITE" && pop_ctx
}

function redis_flushall() {
  local conn_ctx=$1
  push_ctx ${conn_ctx} && exec_cmd "$(cmd_echo redis_conn) FLUSHALL" && pop_ctx
}
