function sqlx_envs() {
  local envs=(DATABASE_URL)
  echo "${envs}"
}

function ctx_crate_cargo_sonar() {
  ctx_cargo_crate || return $?
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
}

DT_BINDINGS+=(ctx_crate_sqlx:sqlx:cargo_install_methods)

function database_url() {
  echo "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

function sqlx_pre_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "SCHEMAS TMP_SCHEMAS" || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  cmd_exec "find '${SCHEMAS}' -type f | while read FILE; do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done"
}

function sqlx_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  sqlx_pre_run || return $?
  cmd_exec $(inline_vars "$(sqlx_envs)") sqlx migrate run --source "'${TMP_SCHEMAS}'"
}

function sqlx_prepare() {
  cmd_exec cd "${DT_PROJECT_DIR}"
  cmd_exec "cargo sqlx prepare" #--workspace
}

function sqlx_methods() {
  local methods=()
  methods+=(sqlx_pre_run)
  methods+=(sqlx_run)
  methods+=(sqlx_prepare)
  echo "${methods[@]}"
}

# Example:
function ctx_sqlx() {
  ctx_conn_migrator_pg && ctx_conn_pg || return $?
  var SCHEMAS "${DT_PROJECT}/migrations/schemas"
  var TMP_SCHEMAS "${DT_ARTEFACTS}/schemas"
  var DATABASE_URL $(database_url)
}

DT_BINDINGS+=(ctx_sqlx:default:sqlx_methods)
