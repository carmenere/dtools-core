function pg_sql_alter_role_password() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  dt_err_if_empty ${fname} "PGPASSWORD" || return $?
  query=$(
    dt_escape_quote "ALTER ROLE \"${PGUSER}\" WITH PASSWORD '${PGPASSWORD}'"
  )
  echo "${query}"
}

# In postgres the $$ ... $$ means dollar-quoted string.
# So, we must escape each $ to avoid bash substitution: \$\$ ... \$\$.
function pg_sql_create_user() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  dt_err_if_empty ${fname} "PGPASSWORD" || return $?
  query=$(
    dt_escape_quote "
    SELECT \$\$CREATE USER ${PGUSER} WITH ENCRYPTED PASSWORD '${PGPASSWORD}'\$\$
    WHERE NOT EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
  ")
  echo "${query}"
}

function pg_sql_drop_user() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  query=$(
    echo "DROP USER IF EXISTS ${PGUSER}"
  )
  echo "${query}"
}

function pg_sql_create_db() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGDATABASE" || return $?
  query=$(
    dt_escape_quote "
    SELECT 'CREATE DATABASE ${PGDATABASE}'
    WHERE NOT EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
  ")
  echo "${query}"
}

function pg_sql_drop_db() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGDATABASE" || return $?
  query=$(
    dt_escape_quote "
    SELECT 'DROP DATABASE IF EXISTS ${PGDATABASE}'
    WHERE EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
  ")
  echo "${query}"
}

function pg_sql_grant_user_migrator() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  dt_err_if_empty ${fname} "PGDATABASE" || return $?
  query=$(
    dt_escape_quote "
      SELECT
        'ALTER ROLE ${PGUSER} WITH SUPERUSER CREATEDB',
        'ALTER DATABASE ${PGDATABASE} OWNER TO ${PGUSER}'
      WHERE
        EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
        AND
        EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
  ")
  echo "${query}"
}

function pg_sql_revoke_user_migrator() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  query=$(
    dt_escape_quote "
      SELECT 'DROP OWNED BY ${PGUSER}'
      WHERE EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
  ")
  echo "${query}"
}

function pg_sql_grant_user_app() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  dt_err_if_empty ${fname} "PGDATABASE" || return $?
  query=$(
    dt_escape_quote "
    SELECT
      'GRANT USAGE ON SCHEMA public TO ${PGUSER}',
      'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO ${PGUSER}',
      'GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO ${PGUSER}',
      'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${PGUSER}',
      'GRANT CONNECT ON DATABASE ${PGDATABASE} TO ${PGUSER}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
      AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
  ")
  echo "${query}"
}

function pg_sql_revoke_user_app() {
  local fname query
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGUSER" || return $?
  dt_err_if_empty ${fname} "PGDATABASE" || return $?
  query=$(
    dt_escape_quote "
    SELECT
      'REVOKE SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public FROM ${PGUSER}',
      'REVOKE USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public FROM ${PGUSER}',
      'REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM ${PGUSER}',
      'REVOKE CONNECT ON DATABASE ${PGDATABASE} FROM ${PGUSER}',
      'REVOKE ALL PRIVILEGES ON DATABASE ${PGDATABASE} FROM ${PGUSER}',
      'REVOKE ALL ON SCHEMA public FROM ${PGUSER}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${PGUSER}')
      AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${PGDATABASE}')
  ")
  echo "${query}"
}
