function clickhouse_conn() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local cmd=("clickhouse-client")
  if [ -n "${CLICKHOUSE_HOST}" ]; then cmd+=(--host "${CLICKHOUSE_HOST}"); fi
  if [ -n "${CLICKHOUSE_PORT}" ]; then cmd+=(--port "${CLICKHOUSE_PORT}"); fi
  if [ -n "${CLICKHOUSE_DB}" ]; then cmd+=(--database "${CLICKHOUSE_DB}"); fi
  if [ -n "${CLICKHOUSE_USER}" ]; then cmd+=(--user "${CLICKHOUSE_USER}"); fi
  if [ -n "${CLICKHOUSE_PASSWORD}" ]; then cmd+=(--password "${CLICKHOUSE_PASSWORD}"); fi
  dt_exec "${cmd[@]}"
}

function clickhouse_client_create_db() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local query="$(${query_ctx} && clickhouse_sql_create_db)"
  local conn="$(${conn_ctx} && dt_echo clickhouse_conn)"
  local cmd="${conn} --multiquery $'${query}'"
  dt_exec "${cmd}"
}

function clickhouse_client_drop_db() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local query="$(${query_ctx} && clickhouse_sql_drop_db)"
  local conn="$(${conn_ctx} && dt_echo clickhouse_conn)"
  local cmd="${conn} --multiquery $'${query}'"
  dt_exec "${cmd}"
}

function clickhouse_client_create_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local query="$(${query_ctx} && clickhouse_sql_create_user)"
  local conn="$(${conn_ctx} && dt_echo clickhouse_conn)"
  local cmd="${conn} --multiquery $'${query}'"
  dt_exec "${cmd}"
}

function clickhouse_client_drop_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local query="$(${query_ctx} && clickhouse_sql_drop_user)"
  local conn="$(${conn_ctx} && dt_echo clickhouse_conn)"
  local cmd="${conn} --multiquery $'${query}'"
  dt_exec "${cmd}"
}

function clickhouse_client_grant_user() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local query_ctx=$1; dt_err_if_empty ${fname} "query_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
  local query="$(${query_ctx} && clickhouse_sql_grant_user)"
  local conn="$(${conn_ctx} && dt_echo clickhouse_conn)"
  local cmd="${conn} --multiquery $'${query}'"
  dt_exec "${cmd}"
}

function clickhouse_conn_admin() { ( ctx_conn_clickhouse_admin && clickhouse_conn ) }
function clickhouse_conn_app() { ( ctx_conn_clickhouse_app && clickhouse_conn ) }
function clickhouse_conn_docker_admin() { ( ctx_conn_docker_clickhouse_admin && clickhouse_conn ) }
function clickhouse_conn_docker_app() { ( ctx_conn_docker_clickhouse_app && clickhouse_conn ) }

function _clickhouse_client_init() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    admin=$1; dt_err_if_empty ${fname} "admin"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
    app=$2; dt_err_if_empty ${fname} "app"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
    clickhouse_client_create_db $app $admin && \
    clickhouse_client_create_user $app $admin && \
    clickhouse_client_grant_user $app $admin
  )
}

function _clickhouse_client_clean() {
  (
    local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
    admin=$1; dt_err_if_empty ${fname} "admin"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
    app=$2; dt_err_if_empty ${fname} "app"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
    clickhouse_client_drop_db $app $admin && \
    clickhouse_client_drop_user $app $admin
  )
}

function clickhouse_client_conn_admin() {( ctx_conn_clickhouse_admin && clickhouse_client_conn )}
function clickhouse_client_conn_app() {( ctx_conn_clickhouse_app && clickhouse_client_conn )}

function clickhouse_client_init() {(
  _clickhouse_client_init ctx_conn_clickhouse_admin ctx_conn_clickhouse_app
)}
function clickhouse_client_clean() {(
  _clickhouse_client_clean ctx_conn_clickhouse_admin ctx_conn_clickhouse_app
)}

function clickhouse_client_conn_docker_admin() {( ctx_conn_docker_clickhouse_admin && clickhouse_client_conn )}
function clickhouse_client_conn_docker_app() {( ctx_conn_docker_clickhouse_app && clickhouse_client_conn )}

function clickhouse_client_init_docker() {(
  docker_service_check_clickhouse && \
  _clickhouse_client_init ctx_conn_docker_clickhouse_admin ctx_conn_docker_clickhouse_app
)}

# it's like docker_rm_clickhouse && docker_run_clickhouse
function clickhouse_client_clean_docker() {(
  _clickhouse_client_clean ctx_conn_docker_clickhouse_admin ctx_conn_docker_clickhouse_app
)}
