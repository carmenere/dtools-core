. ${DT_VARS}/conns/rabbitmq_3.8/defaults.sh

user="example_app"
password="1234567890"
database=0

AUX_CONN=${DT_VARS}/conns/rabbitmq_3.8/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/rabbitmq_3.8/app.sh
source_locals ${LOCALS}