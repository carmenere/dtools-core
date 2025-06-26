function _redis_conn() {
  echo "$(CLIENT) -e -u redis://$(REDIS_USER):$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/$(REDIS_DB)" $@
}

function _redis_exec() {
  local conn_ctx="$1" query="$2" conn_type="$3" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "conn_ctx query" && \
  query=$(${query}) && \
  switch_ctx ${conn_ctx} && \
  $(EXEC) "$(_redis_conn) ${query}"
}

function _redis_init() {
  local admin="$1" app="$2" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}" && \
  err_if_empty ${fname} "admin app" && \
  if ! ${app}__redis_check_user; then
    ${app}__redis_create_user && \
    ${admin}__redis_set_requirepass && \
    ${admin}__redis_config_rewrite
  fi
}

function _redis_clean() {
  local admin="$1" app="$2" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}" && \
  err_if_empty ${fname} "admin app" && \
  if ${app}__redis_check_user; then
    ${app}__redis_drop_user && \
    ${admin}__redis_flushall && \
    ${admin}__redis_config_rewrite
  fi
}

function redis_conn() { $(TERMINAL) "$(_redis_conn $@)"; }

function redis_check_user() { _redis_exec $(CONN) ql_redis_check_user; }
function redis_config_rewrite() { _redis_exec $(CONN) ql_redis_config_rewrite; }
function redis_create_user() { _redis_exec $(CONN) ql_redis_create_user; }
function redis_drop_user() { _redis_exec $(CONN) ql_redis_drop_user; }
function redis_flushall() { _redis_exec $(CONN) ql_redis_flushall; }
function redis_set_requirepass() { _redis_exec $(CONN) ql_redis_set_requirepass; }

function redis_methods() {
  local methods=()
  methods+=(redis_check_user)
  methods+=(redis_config_rewrite)
  methods+=(redis_conn)
  methods+=(redis_create_user)
  methods+=(redis_drop_user)
  methods+=(redis_flushall)
  methods+=(redis_set_requirepass)
  echo "${methods[@]}"
}
