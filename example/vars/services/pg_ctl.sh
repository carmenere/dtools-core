. ${DT_VARS}/services/pg_17.sh

SERVICE="pg_ctl"

user=$(. ${DT_VARS}/conns/pg_ctl_17/_admin.sh && echo ${user})
password=$(. ${DT_VARS}/conns/pg_ctl_17/_admin.sh && echo ${password})

HOST_BIND="localhost"
PORT_BIND=5444
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"

OS_USER="${user}"
PG_DATADIR="${DT_ARTEFACTS}/pg_ctl/data"
INITDB_AUTH_HOST="md5"
INITDB_AUTH_LOCAL="peer"
INITDB_PWFILE="/tmp/passwd.tmp"
PG_CTL_LOGGING_COLLECTOR="on"
PG_CTL_CONF="${PG_DATADIR}/postgresql.conf"
PG_CTL_LOG="${PG_DATADIR}/pg_ctl.logs"
POSTMASTER="${PG_DATADIR}/postmaster.pid"
PG_CONF="${PG_DATADIR}/postgresql.conf"

LOCALS=${DT_LOCAL_VARS}/services/${SERVICE}.sh
source_locals ${LOCALS}