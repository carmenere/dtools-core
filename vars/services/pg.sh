MODE=docker
MODE=host

MAJOR=17
MINOR=5

SERVICE="pg"
OS_SERVICE=$(pg_service)

BIN_DIR=$(pg_bin_dir)
HOST_BIND="localhost"
PORT_BIND="5555"
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"

PSQL="${BIN_DIR}/psql"

EXEC="host_exec"
TERMINAL="host_exec"