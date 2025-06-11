#clickhouse_version=(MAJOR MINOR)
#clickhouse_socket=(CLICKHOUSE_HOST CLICKHOUSE_PORT)
#clickhouse_paths=(CH_USER_XML_DIR CH_USER_XML CH_CONFIG_XML)
#
#function clickhouse_vars() {
#  echo "${clickhouse_version[@]} ${clickhouse_socket[@]} ${clickhouse_paths[@]} ${service[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
#}
#
#function clickhouse_docker_vars() {
#  echo "$(docker_vars) $(clickhouse_vars)" | xargs -n1 | sort -u | xargs
#}
#
#clickhouse_account=(CLICKHOUSE_USER CLICKHOUSE_DB CLICKHOUSE_PASSWORD)
#
#function clickhouse_account_vars() {
#  echo "${clickhouse_account[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
#}
#
#
#fucntion abc() {
#  vars=(AAA BBB)
#  local AAA=111
#  declare -p BBB
#}