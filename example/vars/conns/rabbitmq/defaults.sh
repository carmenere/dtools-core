. <(set -eu; . ${DT_VARS}/services/rabbitmq_3.8.sh
  echo "MODE=${MODE}"
  echo "SERVICE=${SERVICE}"
  echo "port_app=${PORT_CONN}"
  echo "port_client=${PORT_CONN_MGM}"
  echo "host=${HOST_CONN}"
  echo "EXEC=${EXEC}"
  echo "TERMINAL=${TERMINAL}"
#  echo "CLIENT=${CLIENT}"
)

if [ "${MODE}" = "docker" ]; then
  . <(set -eu; . ${DT_VARS}/docker_services/rabbitmq_3.8.sh
    echo "port_app=${PORT_CONN}"
    echo "port_client=${PORT_CONN_MGM}"
    echo "host=${HOST_CONN}"
    echo "EXEC=${EXEC}"
    echo "TERMINAL=${TERMINAL}"
#    echo "CLIENT=${CLIENT}"
  )
fi
