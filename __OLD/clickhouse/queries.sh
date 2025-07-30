function sql_click_create_user() {
  local query=$(
    escape_quote "CREATE USER IF NOT EXISTS $(CLICKHOUSE_USER) IDENTIFIED WITH sha256_password BY '$(CLICKHOUSE_PASSWORD)';"
  ) || return $?
  echo "${query}"
}

function sql_click_drop_user() {
  local query=$(
    escape_quote "DROP USER IF EXISTS $(CLICKHOUSE_USER);"
  ) || return $?
  echo "${query}"
}

function sql_click_create_db() {
  local query=$(
    escape_quote "CREATE DATABASE IF NOT EXISTS $(CLICKHOUSE_DB);"
  ) || return $?
  echo "${query}"
}

function sql_click_drop_db() {
  local query=$(
    escape_quote "DROP DATABASE IF EXISTS $(CLICKHOUSE_DB);"
  ) || return $?
  echo "${query}"
}

function sql_click_grant_user() {
  local query=$(
    escape_quote "GRANT ALL ON $(CLICKHOUSE_DB).* TO $(CLICKHOUSE_USER); GRANT ALL ON default.* TO $(CLICKHOUSE_USER);"
  ) || return $?
  echo "${query}"
}

function sql_click_revoke_user() {
  local query=$(
    escape_quote "REVOKE ALL ON $(CLICKHOUSE_DB).* TO $(CLICKHOUSE_USER); GRANT ALL ON default.* TO $(CLICKHOUSE_USER);"
  ) || return $?
  echo "${query}"
}