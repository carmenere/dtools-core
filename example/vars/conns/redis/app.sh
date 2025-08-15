. ${DT_VARS}/conns/redis_7.2/defaults.sh

user="example_app"
password="1234567890"
database=0

AUX_CONN=${DT_VARS}/conns/redis_7.2/admin.sh

LOCALS=${DT_LOCAL_VARS}/conns/redis_7.2/app.sh
source_locals ${LOCALS}