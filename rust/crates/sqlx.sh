function ctx_crate_sqlx() {
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  FORCE=
  FROZEN=
  IGNORE_RUST_VERSION=
  LOCKED="y"
  OFFLINE=
}

function cargo_install_sqlx() { cargo_install ctx_crate_sqlx }
function cargo_uninstall_sqlx() { cargo_uninstall ctx_crate_sqlx }

function ctx_sqlx() {
  SCHEMAS="${DT_PROJECT}/migrations/schemas"
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

function sqlx_pre_run() {
  dt_err_if_empty $0 "SCHEMAS"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMP_SCHEMAS"; exit_on_err $0 $? || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  cmd=("find '${SCHEMAS}' -type f | while read FILE; do ")
  cmd+=('echo cp ${BOLD}${FILE}${RESET} "${TMP_SCHEMAS}/"; ')
  cmd+=('cp "${FILE}" "${TMP_SCHEMAS}/"; done')
  dt_exec_or_echo "${cmd}" $mode
}

function sqlx_run() {
  local _inline_envs=(DATABASE_URL)
  dt_err_if_empty $0 "TMP_SCHEMAS"; exit_on_err $0 $? || return $?
  sqlx_pre_run $ctx $mode
  cmd=("$(dt_inline_envs)")
  cmd+=(sqlx migrate run)
  cmd+=(--source "'${TMP_SCHEMAS}'")
  dt_exec_or_echo "${cmd}" $mode
}

function sqlx_prepare() {
  ( cd "${DT_PROJECT_DIR}" && dt_exec_or_echo "cargo sqlx prepare" ) #--workspace
}
