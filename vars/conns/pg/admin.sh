ACCOUNT=${DT_VARS}/conns/accounts/pg/admin.sh
CONN=${ACCOUNT}

. <(set -eu; . ${DT_VARS}/services/pg.sh
  echo "MODE=${MODE}"
  echo "SERVICE_ID=${SERVICE_ID}"

  echo "port=${PORT_CONN}"
  echo "port_psql=${PORT_CONN}"
  echo "host=${HOST_CONN}"
  echo "EXEC=${EXEC}"
  echo "TERMINAL=${TERMINAL}"
  echo "PSQL=${PSQL}"
)

if [ "$(service_mode)" = "docker" ]; then
  . <(set -eu; . ${DT_VARS}/docker_services/pg.sh
    echo "port=${PORT_CONN}"
    echo "port_psql=${PORT_BIND}"
    echo "host=${HOST_CONN}"
    echo "EXEC=${EXEC}"
    echo "TERMINAL=${TERMINAL}"
    echo "PSQL=${PSQL}"
  )
fi