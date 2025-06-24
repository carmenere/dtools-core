function ql_redis_create_user() {
  local query=$(escape_quote "ACL SETUSER $(REDIS_USER) \>$(REDIS_PASSWORD) on allkeys allcommands") || return $?
  echo "${query}"
}

function ql_redis_drop_user() {
  local query=$(escape_quote "ACL DELUSER $(REDIS_USER)") || return $?
  echo "${query}"
}

function ql_redis_check_user() {
  local query=$(escape_quote "ACL DRYRUN $(REDIS_USER) PING") || return $?
  echo "${query}"
}

function ql_redis_set_requirepass() { echo "config set requirepass \"\""; }
function ql_redis_config_rewrite() { echo "CONFIG REWRITE"; }
function ql_redis_flushall() { echo "FLUSHALL"; }
