MODE=host

MAJOR=3
MINOR=8
PATCH=3

SERVICE="rabbitmq"
OS_SERVICE=$(rmq_service)

HOST_BIND="localhost"
PORT_BIND="5672"
PORT_BIND_MGM="15672"
HOST_CONN="${HOST_BIND}"
PORT_CONN="${PORT_BIND}"
PORT_CONN_MGM="${PORT_BIND_MGM}"

QUEUES='notification ems.error ems.result ems.task'
EXCHANGES="ems"

EXEC="host_exec"
TERMINAL="host_exec"

LOCALS=${DT_LOCAL_VARS}/services/${SERVICE}.sh
source_locals ${LOCALS}