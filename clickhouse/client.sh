function clickhouse_exec() {
  local fname query_ctx conn_ctx query conn cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}"
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  query=$3; dt_err_if_empty ${fname} "query" || return $?
  dt_load_vars -c ${query_ctx} && \
  query=$(${query}) && \
  dt_load_vars -c ${conn_ctx} && \
  conn="$(dt_echo clickhouse_conn)" || return $?
  cmd="${conn} --multiquery $'${query}'"
  dt_exec ${fname} "${cmd}"
}

function clickhouse_conn() {
  local fname conn_url cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  cmd=("clickhouse-client")
  if [ -n "${CLICKHOUSE_HOST}" ]; then cmd+=(--host "${CLICKHOUSE_HOST}"); fi
  if [ -n "${CLICKHOUSE_PORT}" ]; then cmd+=(--port "${CLICKHOUSE_PORT}"); fi
  if [ -n "${CLICKHOUSE_DB}" ]; then cmd+=(--database "${CLICKHOUSE_DB}"); fi
  if [ -n "${CLICKHOUSE_USER}" ]; then cmd+=(--user "${CLICKHOUSE_USER}"); fi
  if [ -n "${CLICKHOUSE_PASSWORD}" ]; then cmd+=(--password "${CLICKHOUSE_PASSWORD}"); fi
  dt_exec ${fname} "${cmd[@]}"
}

function clickhouse_create_db() { clickhouse_exec $1 $2 clickhouse_sql_create_db; }
function clickhouse_create_user() { clickhouse_exec $1 $2 clickhouse_sql_create_user; }
function clickhouse_drop_db() { clickhouse_exec $1 $2 clickhouse_sql_drop_db; }
function clickhouse_drop_user() { clickhouse_exec $1 $2 clickhouse_sql_drop_user; }
function clickhouse_grant_user() { clickhouse_exec $1 $2 clickhouse_sql_grant_user; }

function _clickhouse_init() {
  local fname admin app
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  admin=$1
  app=$2
  clickhouse_create_db $app $admin && \
  clickhouse_create_user $app $admin && \
  clickhouse_grant_user $app $admin
}

function _clickhouse_clean() {
  local fname admin app
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  admin=$1
  app=$2
  clickhouse_drop_db $app $admin && \
  clickhouse_drop_user $app $admin
}

function clickhouse_conn_admin() {( dt_load_vars -c ctx_clickhouse_admin && clickhouse_conn; )}
function clickhouse_conn_app() {( dt_load_vars -c ctx_clickhouse_app && clickhouse_conn; )}
function clickhouse_conn_admin() {( dt_load_vars -c ctx_clickhouse_admin && clickhouse_conn; )}
function clickhouse_conn_app() {( dt_load_vars -c ctx_clickhouse_app && clickhouse_conn; )}

function clickhouse_init() {(
  dt_load_vars -c ctx_service_clickhouse && \
  _clickhouse_init ctx_clickhouse_admin ctx_clickhouse_app
)}

function clickhouse_clean() {(
  dt_load_vars -c ctx_service_clickhouse && \
  _clickhouse_clean ctx_clickhouse_admin ctx_clickhouse_app
)}

function clickhouse_conn_docker_admin() {(
  docker_service_check_clickhouse && \
  dt_load_vars -c ctx_clickhouse_admin && clickhouse_conn
)}

function clickhouse_conn_docker_app() {(
  docker_service_check_clickhouse && \
  dt_load_vars -c ctx_clickhouse_app && clickhouse_conn
)}

function clickhouse_init_docker() {(
  docker_service_check_clickhouse && \
  dt_load_vars -c ctx_docker_clickhouse && \
  _clickhouse_init ctx_clickhouse_admin ctx_clickhouse_app
)}

# You get the same effect if run "docker_rm_clickhouse && docker_run_clickhouse"
function clickhouse_clean_docker() {(
  docker_service_check_clickhouse && \
  dt_load_vars -c ctx_docker_clickhouse && \
  _clickhouse_clean ctx_clickhouse_admin ctx_clickhouse_app
)}
