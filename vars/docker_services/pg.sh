SERVICE="postgres"
IMAGE="$(docker_arm64v8)postgres:17.5-alpine3.21"

HOST_CONN=2222
PORT_CONN=2222
HOST_BIND="localhost"
PORT_BIND=5432

PUBLISH="${PORT_CONN}:${PORT_BIND}/tcp"

PSQL=psql

declare -A run_envs
RUN_ENVS=()
add_run_env POSTGRES_PASSWORD "12345"
add_run_env POSTGRES_DB "postgres"
add_run_env POSTGRES_USER "postgres"