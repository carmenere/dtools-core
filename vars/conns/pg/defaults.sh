. <(set -eu; . ${DT_VARS}/services/pg.sh
  echo "MODE=${MODE}"
  echo "SERVICE=${SERVICE}"
  echo "port=${PORT_CONN}"
  echo "port_psql=${PORT_BIND}"
  echo "host=${HOST_CONN}"
  echo "EXEC=${EXEC}"
  echo "TERMINAL=${TERMINAL}"
  echo "PSQL=${PSQL}"
)

if [ "${MODE}" = "docker" ]; then
  . <(set -eu; . ${DT_VARS}/docker_services/pg.sh
    echo "port=${PORT_CONN}"
    echo "port_psql=${PORT_BIND}"
    echo "host=${HOST_CONN}"
    echo "EXEC=${EXEC}"
    echo "TERMINAL=${TERMINAL}"
    echo "PSQL=${PSQL}"
  )
fi
