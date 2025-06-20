pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars[@]}"
}

ctx_conn_admin_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  if [ "$(os_name)" = "macos" ] && [ "${PROFILE_PG}" = "host" ]; then
    var PGUSER "${USER}"
  else
    var PGUSER "postgres"
  fi
  var PGPASSWORD "postgres"
  var PGDATABASE "postgres"
  $(select_service_pg) && \
  ctx_epilog ${fname}
}

ctx_conn_migrator_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var PGUSER "example_migrator"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service_pg) && \
  ctx_epilog ${fname}
}

ctx_conn_app_pg() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var PGUSER "example_app"
  var PGPASSWORD "1234567890"
  var PGDATABASE "example"
  $(select_service_pg) && \
  ctx_epilog ${fname}
}

function psql_init() {
  switch_ctx $(select_service_pg) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_PG}")) && \
  _psql_init "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg" $(select_exec "${PROFILE_PG}")
}

function psql_clean() {
  switch_ctx $(select_service_pg) && \
  $(get_method "${DT_CTX}" $(select_service_check "${PROFILE_PG}")) && \
  _psql_clean "ctx_conn_admin_pg" "ctx_conn_migrator_pg" "ctx_conn_app_pg" $(select_exec "${PROFILE_PG}")
}

function psql_conn_admin() { _psql_conn ctx_conn_admin_pg $(select_exec "${PROFILE_PG}") "$@"; }
function psql_conn_app() { _psql_conn ctx_conn_app_pg $(select_exec "${PROFILE_PG}") "$@"; }
function psql_conn_migrator() { _psql_conn ctx_conn_migrator_pg $(select_exec "${PROFILE_PG}") "$@"; }
