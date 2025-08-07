MODE=docker
MODE=host

MAJOR=7
MINOR=2
PATCH=4

SERVICE="redis"
OS_SERVICE=$(redis_service)

HOST_BIND="localhost"
PORT_BIND="6379"
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"

CLIENT=redis-cli

EXEC="host_exec"
TERMINAL="host_exec"