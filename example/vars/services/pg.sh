MODE=host

MAJOR=17
MINOR=5

SERVICE="pg"
OS_SERVICE=$(pg_service)

BIN_DIR=$(pg_bin_dir)

HOST_BIND="localhost"
PORT_BIND="5545"
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"

CLIENT="${BIN_DIR}/psql"

EXEC="host_exec"
TERMINAL="host_exec"

LOCALS=${DT_LOCAL_VARS}/services/${SERVICE}.sh
source_locals ${LOCALS}