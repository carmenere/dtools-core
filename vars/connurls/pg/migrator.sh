CONN=${DT_VARS}/accounts/pg/admin.sh
ACCOUNT=${DT_VARS}/accounts/pg/migrator.sh
. <(
  . ${DT_VARS}/services/pg.sh
  echo "port=${PORT_CONN}"
  echo "host=${HOST_CONN}"
  echo "EXEC=${EXEC}"
  echo "TERMINAL=${TERMINAL}"
  echo PSQL=${PSQL}
)