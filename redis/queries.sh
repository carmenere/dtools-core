function redis_ql_create_user() {
  local query=$(escape_quote "ACL SETUSER $(REDIS_USER) \>$(REDIS_PASSWORD) on allkeys allcommands") || return $?
  echo "${query}"
}

function redis_ql_drop_user() {
  local query=$(escape_quote "ACL DELUSER $(REDIS_USER)") || return $?
  echo "${query}"
}

function redis_ql_check_user() {
  local query=$(escape_quote "ACL DRYRUN $(REDIS_USER) PING") || return $?
  echo "${query}"
}

function redis_ql_set_requirepass() {
  echo "config set requirepass \"\""
}
