function pg_ctl_initdb() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -f "${PG_CONF}" ]; then dt_info ${fname} "Postgres has already initialized, datadir='$(DATADIR)'"; return 0; fi
  [ -d $(DATADIR) ] || mkdir -p $(DATADIR)
  chown -R $(OS_USER) $(DATADIR)
  bash -c "echo ${PGPASSWORD} > $(INITDB_PWFILE)"

  exec_cmd "${PG_BINDIR}/initdb --pgdata=$(DATADIR) --username="$(PGUSER)" --auth-local="$(INITDB_AUTH_LOCAL)" --auth-host="$(INITDB_AUTH_HOST)" --pwfile="$(INITDB_PWFILE)""

  rm "$(INITDB_PWFILE)"
}

function pg_ctl_start() {
  pg_ctl_initdb
  local cmd=$(echo "${PG_BINDIR}/pg_ctl -D $(DATADIR) -l $(PG_CTL_LOG) -o \"-k $(DATADIR) -c logging_collector=$(PG_CTL_LOGGING_COLLECTOR) -c config_file=$(PG_CTL_CONF) -p $(PGPORT) -h $(PGHOST)\" start")
  exec_cmd "${cmd[@]}"
}

function pg_ctl_stop() {
  [ ! -f ${POSTMASTER} ] || ${PG_BINDIR}/pg_ctl -D $(DATADIR) -o "-k $(DATADIR) -c config_file=$(PG_CTL_CONF)" stop
}

function pg_ctl_clean() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  pg_ctl_stop || return $?
  [ ! -d $(DATADIR) ] || rm -Rf $(DATADIR)
}

function pg_ctl_lsof() {
  sudo lsof -nP -i4TCP@0.0.0.0:$(PGPORT)
  sudo lsof -nP -i4TCP@localhost:$(PGPORT)
}

function pg_ctl_conn() {
  psql_conn
}

function pg_ctl_methods() {
  local methods=()
  methods+=(pg_ctl_clean)
  methods+=(pg_ctl_conn)
  methods+=(pg_ctl_initdb)
  methods+=(pg_ctl_lsof)
  methods+=(pg_ctl_shutdown)
  methods+=(pg_ctl_start)
  methods+=(pg_ctl_stop)
  echo "${methods[@]}"
}

function ctx_pg_ctl() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var PGUSER $(pg_superuser) && \
  var PGPORT 5444 && \
  var PGHOST "localhost" && \
  var OS_USER "$(PGUSER)" && \
  var DATADIR "${DT_ARTEFACTS}/pg_ctl/data" && \
  var INITDB_AUTH_HOST "md5" && \
  var INITDB_AUTH_LOCAL "peer" && \
  var INITDB_PWFILE "/tmp/passwd.tmp" && \
  var PG_CTL_LOGGING_COLLECTOR "on" && \
  var PG_CTL_CONF "$(DATADIR)/postgresql.conf" && \
  var PG_CTL_LOG "$(DATADIR)/pg_ctl.logs" && \
  var POSTMASTER "$(DATADIR)/postmaster.pid" && \
  var PG_CONF "$(DATADIR)/postgresql.conf" && \
  ctx_os_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_pg_ctl:default:pg_ctl_methods)
