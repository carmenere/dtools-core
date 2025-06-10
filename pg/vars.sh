pg_account=(PGUSER PGDATABASE PGPASSWORD)

function pg_account_vars() {
  echo "${pg_account[@]} ${dt_vars[@]}" | xargs -n1 | sort -u | xargs
}

function pg_vars() {
  local vars=(BIN_DIR)
  vars+=(CONFIG_LIBDIR)
  vars+=(CONFIG_SHAREDIR)
  vars+=(MAJOR)
  vars+=(MINOR)
  vars+=(PGHOST)
  vars+=(PGPORT)
  vars+=(PG_CONFIG)
  vars+=(PG_HBA_CONF)
  vars+=(POSTGRESQL_CONF)
  vars+=(PSQL)
  echo "${vars}"
}

function pg_conn_url() {
  local vars=(PGDATABASE)
  vars+=(PGHOST)
  vars+=(PGPASSWORD)
  vars+=(PGPORT)
  vars+=(PGUSER)
  echo "${vars}"
}

function pg_docker_vars() {
  echo "$(docker_vars) $(pg_vars)"
}
