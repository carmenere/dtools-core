# CLICKHOUSE_PORT for clickhouse-client
# CLICKHOUSE_HTTP_PORT for applications
clickhouse_connurl() {
  local vars=(CLICKHOUSE_DB CLICKHOUSE_HOST CLICKHOUSE_PASSWORD CLICKHOUSE_PORT CLICKHOUSE_USER)
  echo "${vars[@]}"
}

clickhouse_host() { if [ -n "$(CLICKHOUSE_HOST)" ]; then echo "--host $(CLICKHOUSE_HOST)"; fi; }
clickhouse_port() { if [ -n "$(CLICKHOUSE_PORT)" ]; then echo "--port $(CLICKHOUSE_PORT)"; fi; }
clickhouse_db() { if [ -n "$(CLICKHOUSE_DB)" ]; then echo "--database $(CLICKHOUSE_DB)"; fi; }
clickhouse_user() { if [ -n "$(CLICKHOUSE_USER)" ]; then echo "--user $(CLICKHOUSE_USER)"; fi; }
clickhouse_password() { if [ -n "$(CLICKHOUSE_PASSWORD)" ]; then echo "--password $(CLICKHOUSE_PASSWORD)"; fi; }

_clickhouse_conn() {
  echo "$(CLIENT) $(clickhouse_host) $(clickhouse_port) $(clickhouse_db) $(clickhouse_user) $(clickhouse_password) $@"
}

_clickhouse_exec() {
  local conn_ctx="$1" query="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && \
  dt_debug ${fname} "conn_ctx=${conn_ctx}, query=${query}" && \
  err_if_empty ${fname} "conn_ctx query" && \
  query=$(${query}) && \
  switch_ctx ${conn_ctx} && \
  $(EXEC) "$(_clickhouse_conn) --multiquery $'${query}'"
}

_clickhouse_init() {
  local migrator="$1" app="$2" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "migrator=${migrator}, app=${app}" && err_if_empty ${fname} "migrator app" && \
  ${migrator}__clickhouse_create_db && \
  ${migrator}__clickhouse_create_user && \
  ${migrator}__clickhouse_grant_user && \
  ${app}__clickhouse_create_user && \
  ${app}__clickhouse_grant_user
}

_clickhouse_clean() {
  local migrator="$1" app="$2" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "migrator=${migrator}, app=${app}" && err_if_empty ${fname} "migrator app" && \
  ${migrator}__clickhouse_drop_db && \
  ${migrator}__clickhouse_drop_user && \
  ${app}__clickhouse_drop_user
}

clickhouse_conn() { $(TERMINAL) "$(_clickhouse_conn $@)"; }

clickhouse_create_db() { _clickhouse_exec $(CONN) sql_click_create_db; }
clickhouse_create_user() { _clickhouse_exec $(CONN) sql_click_create_user; }
clickhouse_drop_db() { _clickhouse_exec $(CONN) sql_click_drop_db; }
clickhouse_drop_user() { _clickhouse_exec $(CONN) sql_click_drop_user; }
clickhouse_grant_user() { _clickhouse_exec $(CONN) $(GRANT); }
clickhouse_revoke_user() { _clickhouse_exec $(CONN) $(REVOKE); }

clickhouse_methods() {
  local methods=()
  methods+=(clickhouse_conn)
  methods+=(clickhouse_create_db)
  methods+=(clickhouse_create_user)
  methods+=(clickhouse_drop_db)
  methods+=(clickhouse_drop_user)
  methods+=(clickhouse_grant_user)
  methods+=(clickhouse_revoke_user)
  echo "${methods[@]}"
}