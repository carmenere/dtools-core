. ${DT_VARS}/services/pg.sh

user=$(. ${DT_VARS}/conns/pg_ctl/_admin.sh && echo ${user})
password=$(. ${DT_VARS}/conns/pg_ctl/_admin.sh && echo ${password})

HOST_BIND="localhost"
PORT_BIND=5444
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"

OS_USER="${user}"
DATADIR="${DT_ARTEFACTS}/pg_ctl/data"
INITDB_AUTH_HOST="md5"
INITDB_AUTH_LOCAL="peer"
INITDB_PWFILE="/tmp/passwd.tmp"
PG_CTL_LOGGING_COLLECTOR="on"
PG_CTL_CONF="${DATADIR}/postgresql.conf"
PG_CTL_LOG="${DATADIR}/pg_ctl.logs"
POSTMASTER="${DATADIR}/postmaster.pid"
PG_CONF="${DATADIR}/postgresql.conf"
