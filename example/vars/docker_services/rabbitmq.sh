. ${DT_VARS}/docker_services/defaults.sh

# Docker service and OS service must share the same SERVICE, because it is used in conns
SERVICE=$(. ${DT_VARS}/services/rabbitmq_3.8.sh && echo ${SERVICE})
# By default, SERVICE is a name of container
CONTAINER="${SERVICE}"

. <(set -ue; . ${DT_VARS}/docker_images/${SERVICE}.sh
  echo "IMAGE=${IMAGE}"
)

. <(set -ue; . ${DT_VARS}/docker_bridges/example.sh
  echo BRIDGE="${BRIDGE}"
)

HOST_CONN="localhost"
PORT_CONN=5680
HOST_BIND="localhost"
PORT_BIND=5672

HOST_CONN_MGM="localhost"
PORT_CONN_MGM=15672
HOST_BIND_MGM="localhost"
PORT_BIND_MGM=15672

add_publish "${PORT_CONN}:${PORT_BIND}/tcp"

LOCALS=${DT_LOCAL_VARS}/docker_images/${SERVICE}.sh
source_locals ${LOCALS}