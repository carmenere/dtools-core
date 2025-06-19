pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars[@]}"
}

ctx_conn_admin_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  if [ "$(os_name)" = "macos" ] && [ "${PROFILE_PG}" = "host" ]; then
    var PGUSER "${USER}"
  else
    var PGUSER "postgres"
  fi
  var PGPASSWORD "postgres"
  var PGDATABASE "postgres"
  $(select_service ${PROFILE_PG} "pg") && \
  ctx_epilog ${fname}
}

ctx_conn_migrator_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var PGUSER "example_migrator"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service ${PROFILE_PG} "pg") && \
  ctx_epilog ${fname}
}

ctx_conn_app_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var PGUSER "example_app"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service ${PROFILE_PG} "pg") && \
  ctx_epilog ${fname}
}

function psql_init() {
  $(select_checker ${PROFILE_PG} "pg") && \
  _psql_init "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg"
}

function psql_clean() {
  $(select_checker ${PROFILE_PG} "pg") && \
  _psql_clean "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg"
}

function psql_conn_admin() { _psql_conn ctx_conn_admin_pg "$@"; }
function psql_conn_app() { _psql_conn ctx_conn_app_pg "$@"; }
function psql_conn_migrator() { _psql_conn ctx_conn_migrator_pg "$@"; }
