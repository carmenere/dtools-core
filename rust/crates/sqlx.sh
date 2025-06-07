function ctx_crate_sqlx() {
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED="y"
  OFFLINE=
}

dt_register "ctx_crate_sqlx" "sqlx" "${cargo_install_methods[@]}"

function sqlx_vars() {
  sqlx_vars=(SCHEMAS TMP_SCHEMAS DATABASE_URL)
  echo "${sqlx_vars[@]}" | xargs -n1 | sort -u | xargs
}

function ctx_sqlx() {
  local ctx=$0; dt_skip_if_initialized && return 0
  __vars=$(sqlx_vars)
  SCHEMAS="${DT_PROJECT}/migrations/schemas"
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
  dt_set_ctx -c ${ctx}
}

function sqlx_pre_run() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "SCHEMAS" || return $?
  dt_err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  local cmd=("find '${SCHEMAS}' -type f | while read FILE; ")
  cmd+=("do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done")
  dt_exec ${fname} "${cmd[@]}"
}

function sqlx_run() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local _envs=(DATABASE_URL)
  dt_err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  sqlx_pre_run $ctx
  local cmd=("$(dt_inline_envs "${_envs[@]}")")
  cmd+=(sqlx migrate run)
  cmd+=(--source "'${TMP_SCHEMAS}'")
  dt_exec ${fname} "${cmd[@]}"
}

function sqlx_prepare() {
  ( cd "${DT_PROJECT_DIR}" && dt_exec ${fname} "cargo sqlx prepare" ) #--workspace
}

sqlx_methods=()

sqlx_methods+=(sqlx_pre_run)
sqlx_methods+=(sqlx_run)
sqlx_methods+=(sqlx_prepare)
