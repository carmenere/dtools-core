select_service_redis() {
  if [ "${PROFILE_REDIS}" = "docker" ]; then echo "ctx_docker_redis"; else echo "ctx_service_redis"; fi
}

function _redis_conn_cmd() {
  echo "redis-cli -e -u redis://$(REDIS_USER):$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB)" $@
}

function _redis_conn() {
  local conn_ctx="$1" exec="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  shift 2 && \
  err_if_empty ${fname} "exec conn_ctx" && \
  ${conn_ctx} && \
  ${exec} $(_redis_conn_cmd $@)
}

function _redis_cmd() {
  local fname conn query_ctx=$1 conn_ctx=$2 query=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}, conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "query_ctx conn_ctx query" && \
  query=$(switch_ctx ${query_ctx} && ${query}) && \
  conn="$(switch_ctx ${conn_ctx} && _redis_conn_cmd)" && \
  echo "${conn} ${query}"
}

function _redis_init() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  if ! ${exec} "$(_redis_cmd ${app} ${admin} redis_ql_check_user)"; then
    ${exec} "$(_redis_cmd ${app} ${admin} redis_ql_create_user)" && \
    ${exec} "$(switch_ctx ${admin} && _redis_conn_cmd) config set requirepass \"\""
    ${exec} "$(switch_ctx ${admin} && _redis_conn_cmd) CONFIG REWRITE"
  fi
}

function _redis_clean() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  if ${exec} "$(_redis_cmd ${app} ${admin} redis_ql_check_user)"; then
    ${exec} "$(_redis_cmd ${app} ${admin} redis_ql_drop_user)" && \
    ${exec} "$(switch_ctx ${admin} && _redis_conn_cmd) FLUSHALL"
    ${exec} "$(switch_ctx ${admin} && _redis_conn_cmd) CONFIG REWRITE"
  fi
}
