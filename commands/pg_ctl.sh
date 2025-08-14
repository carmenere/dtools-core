pg_ctl_initdb() {
  local fname=pg_ctl_initdb
  if [ -f "${PG_CONF}" ]; then dt_info ${fname} "Postgres has already initialized, datadir='${PG_DATADIR}'"; return 0; fi
  [ -d ${PG_DATADIR} ] || mkdir -p ${PG_DATADIR}
  chown -R ${OS_USER} ${PG_DATADIR}
  bash -c "echo ${password} > ${INITDB_PWFILE}"

  exec_cmd "${BIN_DIR}/initdb --pgdata=${PG_DATADIR} --username="${user}" --auth-local="${INITDB_AUTH_LOCAL}" --auth-host="${INITDB_AUTH_HOST}" --pwfile="${INITDB_PWFILE}""

  rm "${INITDB_PWFILE}"
}

pg_ctl_start() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  pg_ctl_initdb
  local cmd=$(echo "${BIN_DIR}/pg_ctl -D ${PG_DATADIR} -l ${PG_CTL_LOG} -o \"-k ${PG_DATADIR} -c logging_collector=${PG_CTL_LOGGING_COLLECTOR} -c config_file=${PG_CTL_CONF} -p ${PORT_BIND} -h ${HOST_BIND}\" start")
  exec_cmd "${cmd[@]}"
)}

pg_ctl_stop() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  [ ! -f ${POSTMASTER} ] || ${BIN_DIR}/pg_ctl -D ${PG_DATADIR} -o "-k ${PG_DATADIR} -c config_file=${PG_CTL_CONF}" stop
)}

pg_ctl_clean() {(
  local fname=pg_ctl_clean
  set -eu; . "${DT_VARS}/services/$1.sh"
  pg_ctl_stop $1 || return $?
  [ ! -d ${PG_DATADIR} ] || rm -Rf ${PG_DATADIR}
)}

pg_ctl_conn() {(
  set -eu
  psql_conn $1
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_pg_ctl() {
  local methods=()
  methods+=(pg_ctl_clean)
  methods+=(pg_ctl_conn)
  methods+=(pg_ctl_initdb)
  methods+=(pg_ctl_shutdown)
  methods+=(pg_ctl_start)
  methods+=(pg_ctl_stop)
  echo "${methods[@]}"
}
