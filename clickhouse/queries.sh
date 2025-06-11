function clickhouse_sql_create_user() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "CLICKHOUSE_USER" || return $?
  dt_err_if_empty ${fname} "CLICKHOUSE_PASSWORD" || return $?
  query=$(
    dt_escape_quote "CREATE USER IF NOT EXISTS ${CLICKHOUSE_USER} IDENTIFIED WITH sha256_password BY '${CLICKHOUSE_PASSWORD}';"
  )
  echo "${query}"
}

function clickhouse_sql_drop_user() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "CLICKHOUSE_USER" || return $?
  query=$(
    dt_escape_quote "DROP USER IF EXISTS ${CLICKHOUSE_USER};"
  )
  echo "${query}"
}

function clickhouse_sql_create_db() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "CLICKHOUSE_DB" || return $?
  query=$(
    dt_escape_quote "CREATE DATABASE IF NOT EXISTS ${CLICKHOUSE_DB};"
  )
  echo "${query}"
}

function clickhouse_sql_drop_db() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "CLICKHOUSE_DB" || return $?
  query=$(
    dt_escape_quote "DROP DATABASE IF EXISTS ${CLICKHOUSE_DB};"
  )
  echo "${query}"
}

function clickhouse_sql_grant_user() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "CLICKHOUSE_USER" || return $?
  dt_err_if_empty ${fname} "CLICKHOUSE_DB" || return $?
  query=$(
    dt_escape_quote "GRANT ALL ON ${CLICKHOUSE_DB}.* TO ${CLICKHOUSE_USER}; GRANT ALL ON default.* TO ${CLICKHOUSE_USER};"
  )
  echo "${query}"
}