. <(. ${DT_VARS}/services/pg.sh
  echo MODE=${MODE}
)
user="$(pg_superuser)"
password="postgres"
database="postgres"
GRANT=
REVOKE=