function clickhouse_sql_create_user() {
  local query=$(
    dt_escape_single_quotes "CREATE USER IF NOT EXISTS ${CLICKHOUSE_USER} IDENTIFIED WITH sha256_password BY '${CLICKHOUSE_PASSWORD}';"
  )
  echo "${query}"
}

function clickhouse_sql_drop_user() {
  local query=$(
    dt_escape_single_quotes "DROP USER IF EXISTS ${CLICKHOUSE_USER};"
  )
  echo "${query}"
}

function clickhouse_sql_create_db() {
  local query=$(
    dt_escape_single_quotes "CREATE DATABASE IF NOT EXISTS ${CLICKHOUSE_DB};"
  )
  echo "${query}"
}

function clickhouse_sql_drop_db() {
  local query=$(
    dt_escape_single_quotes "DROP DATABASE IF EXISTS ${CLICKHOUSE_DB};"
  )
  echo "${query}"
}

function clickhouse_sql_grant_user() {
  local query=$(
    dt_escape_single_quotes "GRANT ALL ON ${CLICKHOUSE_DB}.* TO ${CLICKHOUSE_USER}; GRANT ALL ON default.* TO ${CLICKHOUSE_USER};"
  )
  echo "${query}"
}