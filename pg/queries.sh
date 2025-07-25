# In postgres the $$ ... $$ means dollar-quoted string.
# For docker mode we must use escaped $$, but for host mode we must use $$ as is
dquote() {
  if [ "$(pg_mode)" = "docker" ]; then
    echo '\$\$'
  else
    echo '$$'
  fi
}

function sql_pg_alter_role_password() {
  local conn=$1 user=$(USER ${conn}) password=$(PASSWORD ${conn})
  local query=$(escape_quote "
    SELECT
      $(dquote) ALTER ROLE \"${user}\" WITH PASSWORD '${password}' $(dquote)
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_role_password() {
  local conn=$1 user=$(USER ${conn}) password=$(PASSWORD ${conn})
  local query=$(escape_quote "
    SELECT
      $(dquote) ALTER ROLE \"${user}\" WITH PASSWORD '${password}' $(dquote)
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
  ") || return $?
  echo "${query}"
}

function sql_pg_create_user() {
  local conn=$1 user=$(USER ${conn}) password=$(PASSWORD ${conn})
  local query=$(escape_quote "
    SELECT
      $(dquote) CREATE USER ${user} WITH ENCRYPTED PASSWORD '${password}' $(dquote)
    WHERE
      NOT EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_user() {
  local conn=$1 user=$(USER ${conn})
  local query=$(escape_quote "
    SELECT
      'DROP OWNED BY ${user}',
      'DROP USER IF EXISTS ${user}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
  ") || return $?
  echo "${query}"
}

function sql_pg_create_db() {
  local conn=$1 database=$(DATABASE ${conn})
  local query=$(escape_quote "
    SELECT
      'CREATE DATABASE ${database}'
    WHERE
      NOT EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_db() {
  local conn=$1 database=$(DATABASE ${conn})
  local query=$(escape_quote "
    SELECT
      'DROP DATABASE IF EXISTS ${database}'
    WHERE
      EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

function sql_pg_grant_user_migrator() {
  local conn=$1 database=$(DATABASE ${conn}) user=$(USER ${conn})
  local query=$(escape_quote "
    SELECT
      'ALTER ROLE ${user} WITH SUPERUSER CREATEDB',
      'ALTER DATABASE ${database} OWNER TO ${user}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

function sql_pg_revoke_user_migrator() {
  local conn=$1 database=$(DATABASE ${conn}) user=$(USER ${conn})
  local query=$(escape_quote "
    SELECT
      'ALTER ROLE ${user} WITH NOSUPERUSER NOCREATEDB',
      'ALTER DATABASE ${database} OWNER TO ${user}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

function sql_pg_grant_user_app() {
  local conn=$1 database=$(DATABASE ${conn}) user=$(USER ${conn})
  local query=$(escape_quote "
    SELECT
      'GRANT USAGE ON SCHEMA public TO ${user}',
      'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO ${user}',
      'GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO ${user}',
      'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${user}',
      'GRANT CONNECT ON DATABASE ${database} TO ${user}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

function sql_pg_revoke_user_app() {
  local conn=$1 database=$(DATABASE ${conn}) user=$(USER ${conn})
  local query=$(escape_quote "
    SELECT
      'REVOKE SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public FROM ${user}',
      'REVOKE USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public FROM ${user}',
      'REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM ${user}',
      'REVOKE CONNECT ON DATABASE ${database} FROM ${user}',
      'REVOKE ALL PRIVILEGES ON DATABASE ${database} FROM ${user}',
      'REVOKE ALL ON SCHEMA public FROM ${user}'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '${user}')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '${database}')
  ") || return $?
  echo "${query}"
}

# Grant syntax with ALL PRIVILEGES and DEFAULT PRIVILEGES
#psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${user};"
#psql -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${user};"
#psql -c "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO ${user};"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${user};"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ${user};"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO ${user};"