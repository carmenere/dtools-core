MODE=docker
MODE=host

MAJOR=23
MINOR=5

SERVICE="clickhouse"
OS_SERVICE=$(ch_service)

CLIENT="clickhouse-client"

HOST_BIND="localhost"
PORT_BIND="9000"
PORT_BIND_HTTP="8123"

HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"
PORT_CONN_HTTP="${PORT_BIND_HTTP}"

EXEC="host_exec"
TERMINAL="host_exec"
