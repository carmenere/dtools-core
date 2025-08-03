. <(. ${DT_VARS}/services/pg.sh && echo MODE=${MODE})
user="$(pg_superuser)"
PASSWORD="postgres"
DATABASE="postgres"
CONN=
GRANT=
REVOKE=