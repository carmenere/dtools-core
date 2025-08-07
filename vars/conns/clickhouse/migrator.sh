. ${DT_VARS}/conns/clickhouse/defaults.sh

user="example_migrator"
password="1234567890"
database="example"
GRANT="grant_user.sql"
REVOKE="revoke_user.sql"

AUX_CONN=${DT_VARS}/conns/clickhouse/admin.sh
