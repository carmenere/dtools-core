divert(-1)dnl
# Parameters for *.sql templates
divert(0)dnl
define(`M4_CLICKHOUSE_USER', ifelse(esyscmd(`printf %s $M4_CLICKHOUSE_USER'), `', `admin', esyscmd(`printf %s $M4_CLICKHOUSE_USER')))dnl
define(`M4_CLICKHOUSE_PASSWORD', ifelse(esyscmd(`printf %s $M4_CLICKHOUSE_PASSWORD'), `', `0987654321', esyscmd(`printf %s $M4_CLICKHOUSE_PASSWORD')))dnl
