function redis_ql_create_user() {
  local query=$( dt_escape_quote "ACL SETUSER ${REDIS_USER} \>${REDIS_PASSWORD} on allkeys allcommands" )
  echo "${query}"
}

function redis_ql_drop_user() {
  local query=$( dt_escape_quote "ACL DELUSER ${REDIS_USER}" )
  echo "${query}"
}

function redis_ql_check_user() {
  local query=$( dt_escape_quote "ACL DRYRUN ${REDIS_USER} PING" )
  echo "${query}"
}

function redis_ql_set_requirepass() {
  echo "config set requirepass \"\""
}
