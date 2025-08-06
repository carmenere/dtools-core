ACCOUNT=${DT_VARS}/conns/accounts/clickhouse/admin.sh
CONN=${ACCOUNT}

. <(set -eu; . ${DT_VARS}/services/clickhouse.sh
  echo "MODE=${MODE}"
  echo "SERVICE_ID=${SERVICE_ID}"

  echo "port_app=${PORT_CONN}"
  echo "port_client=${PORT_CONN}"
  echo "host=${HOST_CONN}"
  echo "EXEC=${EXEC}"
  echo "TERMINAL=${TERMINAL}"
  echo "CLIENT=${CLIENT}"
)

if [ "$(service_mode)" = "docker" ]; then
  . <(set -eu; . ${DT_VARS}/docker_services/clickhouse.sh
    echo "port_app=${PORT_CONN_HTTP}"
    echo "port_client=${PORT_BIND}"
    echo "host=${HOST_CONN}"
    echo "EXEC=${EXEC}"
    echo "TERMINAL=${TERMINAL}"
    echo "CLIENT=${CLIENT}"
  )
fi

dt_debug "xxx" "EXEC=${EXEC}"