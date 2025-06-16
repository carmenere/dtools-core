function ctx_crate_sqlx() {
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED="y"
  OFFLINE=
}

register "ctx_crate_sqlx" "sqlx" "${cargo_install_methods[@]}"

function ctx_sqlx() {
  SCHEMAS="${DT_PROJECT}/migrations/schemas"
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

function sqlx_pre_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "SCHEMAS" || return $?
  err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  local cmd=("find '${SCHEMAS}' -type f | while read FILE; ")
  cmd+=("do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done")
  cmd_exec "${cmd[@]}"
}

function sqlx_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local _envs=(DATABASE_URL)
  err_if_empty ${fname} "TMP_SCHEMAS" || return $?
  sqlx_pre_run $ctx
  local cmd=("$(inline_envs "${_envs[@]}")")
  cmd+=(sqlx migrate run)
  cmd+=(--source "'${TMP_SCHEMAS}'")
  cmd_exec "${cmd[@]}"
}

function sqlx_prepare() {
  ( cd "${PROJECT_DIR}" && cmd_exec "cargo sqlx prepare" ) #--workspace
}

sqlx_methods=()

sqlx_methods+=(sqlx_pre_run)
sqlx_methods+=(sqlx_run)
sqlx_methods+=(sqlx_prepare)
