function ctx_conn_admin_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var RABBIT_USER "guest"
  var RABBIT_PASSWORD "guest"
  $(select_service_rmq) ${caller} && \
  cache_ctx
}

function ctx_conn_app_rmq() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var RABBIT_USER "app_user"
  var RABBIT_PASSWORD 12345
  $(select_service_rmq) ${caller} && \
  cache_ctx
}

function rmq_init() {
  switch_ctx $(select_service_rmq) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_RMQ}")) && \
  _rmq_init "ctx_conn_admin_rmq" "ctx_conn_app_rmq" $(select_exec "${PROFILE_RMQ}")
}

function rmq_clean() {
  switch_ctx $(select_service_rmq) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_RMQ}")) && \
  _rmq_clean "ctx_conn_admin_rmq" "ctx_conn_app_rmq" $(select_exec "${PROFILE_RMQ}")
}

rmq_clean_docker() { docker_rm_rmq; }