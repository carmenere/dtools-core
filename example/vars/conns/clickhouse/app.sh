. ${DT_VARS}/conns/clickhouse_23/defaults.sh

user="example_app"
password="1234567890"
database="example"

GRANT="grant_user.sql"
REVOKE="revoke_user.sql"
AUX_CONN=${DT_VARS}/conns/clickhouse_23/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/clickhouse_23/app.sh
source_locals ${LOCALS}
