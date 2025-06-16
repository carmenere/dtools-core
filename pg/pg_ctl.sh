function ctx_pg_ctl() {
  OS_USER="${PGUSER}"
  DATADIR="${DT_ARTEFACTS}/pg_ctl/data"
  INITDB_AUTH_HOST="md5"
  INITDB_AUTH_LOCAL="peer"
  INITDB_PWFILE="/tmp/passwd.tmp"
  PG_CTL_LOGGING_COLLECTOR="on"
  PG_CTL_CONF="${DATADIR}/postgresql.conf"
  PG_CTL_LOG="${DATADIR}/pg_ctl.logs"
  POSTMASTER="${DATADIR}/postmaster.pid"
  PG_CONF="${DATADIR}/postgresql.conf"
}

function pg_ctl_initdb() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -f "${PG_CONF}" ]; then info ${fname} "Postgres has already initialized, datadir='${DATADIR}'"; return 0; fi
  [ -d ${DATADIR} ] || mkdir -p ${DATADIR}
  chown -R ${OS_USER} ${DATADIR}
  bash -c "echo ${PGPASSWORD} > ${INITDB_PWFILE}"

  cmd_exec "${PG_BINDIR}/initdb --pgdata=${DATADIR} --username="${PGUSER}" --auth-local="${INITDB_AUTH_LOCAL}" --auth-host="${INITDB_AUTH_HOST}" --pwfile="${INITDB_PWFILE}""

  rm "${INITDB_PWFILE}"
}

function pg_ctl_start() {
  pg_ctl_initdb
  local cmd=$(echo "${PG_BINDIR}/pg_ctl -D ${DATADIR} -l ${PG_CTL_LOG} -o \"-k ${DATADIR} -c logging_collector=${PG_CTL_LOGGING_COLLECTOR} -c config_file=${PG_CTL_CONF} -p ${PGPORT} -h ${PGHOST}\" start")
  cmd_exec "${cmd[@]}"
}

function pg_ctl_stop() {
  [ ! -f ${POSTMASTER} ] || ${PG_BINDIR}/pg_ctl -D ${DATADIR} -o "-k ${DATADIR} -c config_file=${PG_CTL_CONF}" stop
}

function pg_ctl_clean() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  pg_ctl_stop || return $?
  [ ! -d ${DATADIR} ] || rm -Rf ${DATADIR}
}

function pg_ctl_lsof() {
  sudo lsof -nP -i4TCP@0.0.0.0:${PGPORT}
  sudo lsof -nP -i4TCP@localhost:${PGPORT}
}

function pg_ctl_conn() {
  psql_conn
}

pg_ctl_methods=()

pg_ctl_methods+=(pg_ctl_initdb)
pg_ctl_methods+=(pg_ctl_start)
pg_ctl_methods+=(pg_ctl_shutdown)
pg_ctl_methods+=(pg_ctl_clean)
pg_ctl_methods+=(pg_ctl_stop)
pg_ctl_methods+=(pg_ctl_lsof)
pg_ctl_methods+=(pg_ctl_conn)

#function ctx_pg_ctl_v17_5444() {
#  ctx_service_pg && \
#  ctx_account_admin_pg && \
#  ctx_pg_ctl || return $?
#  PGPORT=5444
#}

register "ctx_pg_ctl_v17_5444" "v17_5444" "${pg_ctl_methods[@]}"