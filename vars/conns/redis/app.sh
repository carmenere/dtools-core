. ${DT_VARS}/conns/redis/defaults.sh

user="example_app"
password="1234567890"
database=0

AUX_CONN=${DT_VARS}/conns/redis/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/clickhouse/app.sh
source_locals ${LOCALS}