pg_connurl() {
  local vars=(PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER)
  echo "${vars[@]}"
}

function _psql_conn() { echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"; }

function _psql_gexec() {
  local conn_ctx="$1" query="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "conn_ctx query" && \
  query=$(${query}) && \
  switch_ctx ${conn_ctx} && \
  $(EXEC) "echo $'${query}' '\gexec' | $(_psql_conn)"
}

function _psql_init() {
  local spec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "spec=${spec}" && err_if_empty ${fname} "admin migrator app" && \
  if [ -n "${spec}" ]; then spec="_${spec}"; fi && \
  psql_alter_role_password_${admin}${spec} && \
  psql_create_db_${migrator}${spec} && \
  psql_create_user_${migrator}${spec} && \
  psql_grant_user_${migrator}${spec} && \
  psql_create_user_${app}${spec} && \
  psql_grant_user_${app}${spec}
}

function _psql_clean() {
  local spec="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "spec=${spec}" && err_if_empty ${fname} "migrator app" && \
  if [ -n "${spec}" ]; then spec="_${spec}"; fi && \
  psql_drop_db_${migrator}${spec} && \
  psql_drop_user_${migrator}${spec} && \
  psql_drop_user_${app}${spec}
}

function psql_conn() { $(TERMINAL) "$(inline_vars "$(pg_connurl)") $(PSQL) $@"; }
function psql_alter_role_password() { _psql_gexec $(CONN) pg_sql_alter_role_password; }
function psql_create_db() { _psql_gexec $(CONN) pg_sql_create_db; }
function psql_create_user() { _psql_gexec $(CONN) pg_sql_create_user; }
function psql_grant_user() { _psql_gexec $(GRANT_CONN) $(GRANT); }
function psql_drop_db() { _psql_gexec $(CONN) pg_sql_drop_db; }
function psql_drop_user() { _psql_gexec $(CONN) pg_sql_drop_user; }
function psql_revoke_user() { _psql_gexec $(CONN) $(REVOKE); }

function psql_methods() {
  local methods=()
  methods+=(psql_conn)
  methods+=(psql_alter_role_password)
  methods+=(psql_create_db)
  methods+=(psql_create_user)
  methods+=(psql_grant_user)
  methods+=(psql_drop_db)
  methods+=(psql_drop_user)
  methods+=(psql_revoke_user)
  echo "${methods[@]}"
}