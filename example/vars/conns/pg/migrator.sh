. ${DT_VARS}/conns/pg_17/defaults.sh

user="example_migrator"
password="1234567890"
database="example"

GRANT="grant_user_migrator.sql"
REVOKE="revoke_user_migrator.sql"
AUX_CONN=${DT_VARS}/conns/pg_17/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/pg_17/migrator.sh
source_locals ${LOCALS}