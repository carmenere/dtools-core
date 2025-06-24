pg_connurl() {
  local vars=(PGDATABASE PGUSER PGPASSWORD PGHOST PGPORT)
  echo "${vars[@]}"
}

pg_local_connurl() {
  local vars=(PGPORT PGDATABASE PGUSER)
  echo "${vars[@]}"
}

function _psql_conn() { echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"; }
function _psql_local_conn() { echo "$(inline_vars "$(pg_local_connurl)") $(PSQL) $@"; }

function _psql_gexec() {
  local conn="_psql_conn" conn_ctx="$1" query="$2" conn_type="$3" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "conn_ctx query" && \
  query=$(${query}) && \
  if [ "${conn_type}" = "local" ]; then conn="_psql_local_conn"; fi && \
  switch_ctx ${conn_ctx} && \
  $(EXEC) "echo $'${query}' '\gexec' | $(${conn})"
}

function _psql_init() {
  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  err_if_empty ${fname} "admin migrator app" && \
  ${admin}__psql_alter_role_password && \
  ${migrator}__psql_create_db && \
  ${migrator}__psql_create_user && \
  ${migrator}__psql_grant_user && \
  ${app}__psql_create_user && \
  ${app}__psql_grant_user
}

function _psql_clean() {
  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  err_if_empty ${fname} "admin migrator app" && \
  ${migrator}__psql_drop_db && \
  ${migrator}__psql_drop_user && \
  ${app}__psql_drop_user && \
  ${admin}__psql_drop_role_password
}

function psql_alter_role_password() { _psql_gexec $(CONN) sql_pg_alter_role_password "local"; }
function psql_conn() { $(TERMINAL) "$(inline_vars "$(pg_connurl)") $(PSQL) $@"; }
function psql_create_db() { _psql_gexec $(CONN) sql_pg_create_db; }
function psql_create_user() { _psql_gexec $(CONN) sql_pg_create_user; }
function psql_drop_db() { _psql_gexec $(CONN) sql_pg_drop_db; }
function psql_drop_role_password() { _psql_gexec $(CONN) sql_pg_drop_role_password; }
function psql_drop_user() { _psql_gexec $(CONN) sql_pg_drop_user; }
function psql_grant_user() { _psql_gexec $(GRANT_CONN) $(GRANT); }
function psql_revoke_user() { _psql_gexec $(CONN) $(REVOKE); }

function psql_methods() {
  local methods=()
  methods+=(psql_alter_role_password)
  methods+=(psql_conn)
  methods+=(psql_create_db)
  methods+=(psql_create_user)
  methods+=(psql_drop_db)
  methods+=(psql_drop_role_password)
  methods+=(psql_drop_user)
  methods+=(psql_grant_user)
  methods+=(psql_revoke_user)
  echo "${methods[@]}"
}