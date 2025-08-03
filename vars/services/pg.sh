MODE=host
MAJOR=17
MINOR=5
SERVICE=$(pg_service)
BIN_DIR=$(bin_dir)
HOST_BIND="localhost"
PORT_BIND=5555
HOST_CONN=${HOST_BIND}
PORT_CONN=${PORT_BIND}
PSQL=${BIN_DIR}/psql
EXEC="exec_cmd"
TERMINAL="exec_cmd"

if [ "$(mode)" = "docker" ]; then
  . <(
    set -eu; . ${DT_VARS}/docker_services/pg.sh
    echo "PORT_CONN=${PORT_CONN}"
    echo "HOST_CONN=${HOST_CONN}"
    PSQL=psql
  )
fi