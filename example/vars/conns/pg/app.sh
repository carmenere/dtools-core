. ${DT_VARS}/conns/pg_17/migrator.sh

user="example_app"
password="12345"

GRANT="grant_user_app.sql"
REVOKE="revoke_user_app.sql"

LOCALS=${DT_LOCAL_VARS}/conns/pg_17/app.sh
source_locals ${LOCALS}