. ${DT_VARS}/conns/rabbitmq/defaults.sh

user="example_app"
password="1234567890"
database=0

AUX_CONN=${DT_VARS}/conns/rabbitmq/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/clickhouse/app.sh
source_locals ${LOCALS}