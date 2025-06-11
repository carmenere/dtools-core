function sqlx_envs() {
  envs=(DATABASE_URL)
  echo "${envs}"
}

function ctx_crate_sqlx() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  var $c CRATE_NAME "sqlx-cli"
  var $c CRATE_VERSION "0.8.5"
  var $c FORCE
  var $c FROZEN
  var $c IGNORE_RUST_VERSION
  var $c LOCKED "y"
  var $c OFFLINE
  dt_cache ${c}
}

dt_register "ctx_crate_sqlx" "sqlx" "$(cargo_install_methods)"

function ctx_sqlx() {
  local fname c; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  c=$1; if [ -z "${c}" ]; then c=${fname}; if dt_cached ${c}; then return 0; fi; fi;
  load_vars ctx_connurl_pg_migrator "$(psql_conn_url)"
  var $c SCHEMAS "${DT_PROJECT}/migrations/schemas"
  var $c TMP_SCHEMAS "${DT_ARTEFACTS}/schemas"
  var $c DATABASE_URL "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
  dt_cache ${c}
}

function _sqlx_pre_run() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "SCHEMAS" || return $?
  dt_err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  cmd=("find '${SCHEMAS}' -type f | while read FILE; ")
  cmd+=("do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done")
  dt_exec ${fname} "${cmd[@]}"
}

function _sqlx_run() {
  local fname cmd envs
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  _sqlx_pre_run $ctx || return $?
  cmd=($(dt_inline_envs "$(sqlx_envs)"))
  cmd+=(sqlx migrate run)
  cmd+=(--source "'${TMP_SCHEMAS}'")
  dt_exec ${fname} "${cmd[@]}"
}

function _sqlx_prepare() {
  cd "${DT_PROJECT_DIR}" && \
  dt_exec ${fname} "cargo sqlx prepare" #--workspace
}

function sqlx_methods() {
  methods=()
  methods+=(_sqlx_pre_run)
  methods+=(_sqlx_run)
  methods+=(_sqlx_prepare)
  echo "${methods}"
}

dt_register "ctx_sqlx" "default" "$(sqlx_methods)"