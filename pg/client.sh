pg_connurl() {
  local vars=(PGDATABASE PGUSER PGPASSWORD PGHOST PGPORT)
  echo "${vars[@]}"
}

pg_local_connurl() {
  local vars=(PGUSER PGPORT PGDATABASE)
  echo "${vars[@]}"
}

_psql_sudo() {
  if [ "$(pg_mode)" = "docker" ]; then
    echo ""
    return 0
  fi
  if [ -n "$(dt_sudo)" ]; then
    echo "$(dt_sudo) -u $(PGUSER)"
  else
    echo ""
  fi
}

_psql_conn() { echo "$(inline_vars "$(pg_connurl)") $(PSQL) $@"; }
_psql_local_conn() { echo "$(_psql_sudo) $(inline_vars "$(pg_local_connurl)") $(PSQL) $@"; }

_psql_gexec() {
  local conn="_psql_conn" conn_ctx="$1" query="$2" conn_type="$3" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "conn_ctx query" && \
  query=$(${query}) && \
  if [ "${conn_type}" = "local" ]; then conn="_psql_local_conn"; fi && \
  switch_ctx ${conn_ctx} && \
  $(EXEC) "echo $'${query}' '\gexec' | $(${conn})"
}

_psql_init() {
  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  err_if_empty ${fname} "admin migrator app" && \
  ${migrator}__psql_create_db && \
  ${migrator}__psql_create_user && \
  ${migrator}__psql_grant_user && \
  ${app}__psql_create_user && \
  ${app}__psql_grant_user
}

_psql_clean() {
  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
  err_if_empty ${fname} "admin migrator app" && \
  ${migrator}__psql_drop_db && \
  ${migrator}__psql_drop_user && \
  ${app}__psql_drop_user
}

psql_local_conn() { $(TERMINAL) "$(_psql_local_conn $@)"; }
psql_conn() { $(TERMINAL) "$(_psql_conn $@)"; }

psql_alter_role_password() { _psql_gexec $(CONN) sql_pg_alter_role_password "local"; }
psql_create_db() { _psql_gexec $(CONN) sql_pg_create_db; }
psql_create_user() { _psql_gexec $(CONN) sql_pg_create_user; }
psql_drop_db() { _psql_gexec $(CONN) sql_pg_drop_db; }
psql_drop_role_password() { _psql_gexec $(CONN) sql_pg_drop_role_password; }
psql_drop_user() { _psql_gexec $(CONN) sql_pg_drop_user; }
psql_grant_user() { _psql_gexec $(GRANT_CONN) $(GRANT); }
psql_revoke_user() { _psql_gexec $(CONN) $(REVOKE); }

psql_methods() {
  local methods=()
  methods+=(psql_alter_role_password)
  methods+=(psql_conn)
  methods+=(psql_local_conn)
  methods+=(psql_create_db)
  methods+=(psql_create_user)
  methods+=(psql_drop_db)
  methods+=(psql_drop_role_password)
  methods+=(psql_drop_user)
  methods+=(psql_grant_user)
  methods+=(psql_revoke_user)
  echo "${methods[@]}"
}