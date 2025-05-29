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

function ctx_sqlx() {
  SCHEMAS="${DT_PROJECT}/migrations/schemas"
  TMP_SCHEMAS="${DT_ARTEFACTS}/schemas"
  DATABASE_URL="postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
}

function sqlx_pre_run() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  dt_err_if_empty $0 "SCHEMAS"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMP_SCHEMAS"; exit_on_err $0 $? || return $?
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  local cmd=("find '${SCHEMAS}' -type f | while read FILE; ")
  cmd+=("do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done")
  dt_exec_or_echo $mode "${cmd[@]}"
}

function sqlx_run() {
  if [ -n "$1" ]; then local mode="$1"; else local mode='exec'; fi
  local _inline_envs=(DATABASE_URL)
  dt_err_if_empty $0 "TMP_SCHEMAS"; exit_on_err $0 $? || return $?
  sqlx_pre_run $ctx $mode
  local cmd=("$(dt_inline_envs)")
  cmd+=(sqlx migrate run)
  cmd+=(--source "'${TMP_SCHEMAS}'")
  dt_exec_or_echo $mode "${cmd[@]}"
}

function sqlx_prepare() {
  ( cd "${DT_PROJECT_DIR}" && dt_exec_or_echo "cargo sqlx prepare" ) #--workspace
}

sqlx_methods=()

sqlx_methods+=(sqlx_pre_run)
sqlx_methods+=(sqlx_run)
sqlx_methods+=(sqlx_prepare)
