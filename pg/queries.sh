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
  local query=$(escape_quote "
    SELECT
      $(dquote) ALTER ROLE \"$(PGUSER)\" WITH PASSWORD '$(PGPASSWORD)' $(dquote)
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_role_password() {
  local query=$(escape_quote "
    SELECT
      $(dquote) ALTER ROLE \"$(PGUSER)\" WITH PASSWORD '' $(dquote) 
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
  ") || return $?
  echo "${query}"
}

function sql_pg_create_user() {
  local query=$(escape_quote "
    SELECT
      $(dquote) CREATE USER $(PGUSER) WITH ENCRYPTED PASSWORD '$(PGPASSWORD)' $(dquote)
    WHERE
      NOT EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_user() {
  local query=$(escape_quote "
    SELECT
      'DROP OWNED BY $(PGUSER)',
      'DROP USER IF EXISTS $(PGUSER)'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
  ") || return $?
  echo "${query}"
}

function sql_pg_create_db() {
  local query=$(escape_quote "
    SELECT
      'CREATE DATABASE $(PGDATABASE)'
    WHERE
      NOT EXISTS (SELECT true FROM pg_database WHERE datname = '$(PGDATABASE)')
  ") || return $?
  echo "${query}"
}

function sql_pg_drop_db() {
  local query=$(escape_quote "
    SELECT
      'DROP DATABASE IF EXISTS $(PGDATABASE)'
    WHERE
      EXISTS (SELECT true FROM pg_database WHERE datname = '$(PGDATABASE)')
  ") || return $?
  echo "${query}"
}

function sql_pg_grant_user_migrator() {
  local query=$(escape_quote "
    SELECT
      'ALTER ROLE $(PGUSER) WITH SUPERUSER CREATEDB',
      'ALTER DATABASE $(PGDATABASE) OWNER TO $(PGUSER)'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '$(PGDATABASE)')
  ") || return $?
  echo "${query}"
}

#function sql_pg_revoke_user_migrator() {
#  local query=$(escape_quote "
#    SELECT
#      'DROP OWNED BY $(PGUSER)'
#    WHERE
#      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
#  ") || return $?
#  echo "${query}"
#}

function sql_pg_grant_user_app() {
  local query=$(escape_quote "
    SELECT
      'GRANT USAGE ON SCHEMA public TO $(PGUSER)',
      'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO $(PGUSER)',
      'GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO $(PGUSER)',
      'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO $(PGUSER)',
      'GRANT CONNECT ON DATABASE $(PGDATABASE) TO $(PGUSER)'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '$(PGDATABASE)')
  ") || return $?
  echo "${query}"
}

function sql_pg_revoke_user_app() {
  local query=$(escape_quote "
    SELECT
      'REVOKE SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public FROM $(PGUSER)',
      'REVOKE USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public FROM $(PGUSER)',
      'REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM $(PGUSER)',
      'REVOKE CONNECT ON DATABASE $(PGDATABASE) FROM $(PGUSER)',
      'REVOKE ALL PRIVILEGES ON DATABASE $(PGDATABASE) FROM $(PGUSER)',
      'REVOKE ALL ON SCHEMA public FROM $(PGUSER)'
    WHERE
      EXISTS (SELECT true FROM pg_roles WHERE rolname = '$(PGUSER)')
    AND
      EXISTS (SELECT true FROM pg_database WHERE datname = '$(PGDATABASE)')
  ") || return $?
  echo "${query}"
}

# Grant syntax with ALL PRIVILEGES and DEFAULT PRIVILEGES
#psql -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $(PGUSER);"
#psql -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $(PGUSER);"
#psql -c "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $(PGUSER);"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $(PGUSER);"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $(PGUSER);"
#psql -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON FUNCTIONS TO $(PGUSER);"