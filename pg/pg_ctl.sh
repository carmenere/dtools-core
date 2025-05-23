function ctx_pg_ctl() {
  ctx_service_pg
  pg_user_admin
  OS_USER="${PGUSER}"
  DATADIR="${DT_ARTEFACTS}/pg_ctl/data"
  INITDB_AUTH_HOST="md5"
  INITDB_AUTH_LOCAL="peer"
  INITDB_PWFILE="/tmp/passwd.tmp"
  LANG="${LOCALE_LANG}"
  LC_ALL="${LOCALE_LC_ALL}"
  LC_CTYPE="${LOCALE_LC_CTYPE}"
  PG_CTL_LOGGING_COLLECTOR="on"
  PG_CTL_CONF="${DATADIR}/postgresql.conf"
  PG_CTL_LOG="${DATADIR}/pg_ctl.logs"
  POSTMASTER="${DATADIR}/postmaster.pid"
  PG_CONF="${DATADIR}/postgresql.conf"
  PGPORT=5444
}

function pg_ctl_initdb() {
  if [ -f "${PG_CONF}" ]; then dt_info "Postgres has already initialized, datadir='${DATADIR}'"; return 0; fi
  [ -d ${DATADIR} ] || mkdir -p ${DATADIR}
  chown -R ${OS_USER} ${DATADIR}
  bash -c "echo ${PGPASSWORD} > ${INITDB_PWFILE}"

  dt_exec_or_echo "${PG_BINDIR}/initdb --no-locale --encoding=UTF8 --pgdata=${DATADIR} --username="${PGUSER}" --auth-local="${INITDB_AUTH_LOCAL}" --auth-host="${INITDB_AUTH_HOST}" --pwfile="${INITDB_PWFILE}""

  rm "${INITDB_PWFILE}"
}

function pg_ctl_start() {
  pg_ctl_initdb
  cmd=$(echo "${PG_BINDIR}/pg_ctl -D ${DATADIR} -l ${PG_CTL_LOG} -o \"-k ${DATADIR} -c logging_collector=${PG_CTL_LOGGING_COLLECTOR} -c config_file=${PG_CTL_CONF} -p ${PGPORT} -h ${PGHOST}\" start")
  if [ -f "${POSTMASTER}" ]; then "Postgres has already run, postmaster='${POSTMASTER}'"; return 0; fi
  dt_exec_or_echo "${cmd}"
}


function pg_ctl_shutdown() {
  [ ! -f ${POSTMASTER} ] || ${PG_BINDIR}/pg_ctl -D ${DATADIR} -o "-k ${DATADIR} -c config_file=${PG_CTL_CONF}" stop
}

function pg_ctl_clean() {
  [ ! -d ${DATADIR} ] || rm -Rf ${DATADIR}
}

function pg_ctl_stop() {
  pg_ctl_shutdown && \
  pg_ctl_clean
}

function psql_conn_admin_pg_ctl() {
  ctx_pg_ctl && \
  ctx_psql_conn && \
  pg_user_admin && \
  pg_db_postgres && \
  psql_conn
}

function pg_ctl_lsof() {
  sudo lsof -nP -i4TCP@0.0.0.0:${PGPORT}
  sudo lsof -nP -i4TCP@localhost:${PGPORT}
}