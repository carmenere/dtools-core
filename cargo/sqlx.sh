function sqlx_envs() {
  local envs=(DATABASE_URL)
  echo "${envs[@]}"
}

function ctx_crate_cargo_sonar() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  ctx_cargo_crate && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_crate_sqlx:sqlx:cargo_install_methods)

function database_url() {
  echo "postgres://$(PGUSER):$(PGPASSWORD)@$(PGHOST):$(PGPORT)/$(PGDATABASE)"
}

function sqlx_pre_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  non_empty=(SCHEMAS TMP_SCHEMAS)
  for v in ${non_empty[@]}; do if [ -z "$(${v})" ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; fi; done
  rm -rf "$(TMP_SCHEMAS)"
  mkdir -p "$(TMP_SCHEMAS)"
  cmd_exec "find '$(SCHEMAS)' -type f | while read FILE; do echo -e \"cp \${FILE} '$(TMP_SCHEMAS)/'\"; cp "\${FILE}" '$(TMP_SCHEMAS)'; done"
}

function sqlx_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  non_empty=(TMP_SCHEMAS)
  for v in ${non_empty[@]}; do if [ -z "$(${v})" ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; fi; done
  sqlx_pre_run || return $?
  cmd_exec $(inline_vars "$(sqlx_envs)") sqlx migrate run --source "'$(TMP_SCHEMAS)'"
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
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  ctx_prolog ${fname}; if is_cached ${fname}; then return 0; fi; dt_debug ${fname} "DT_CTX=${DT_CTX}"
  var SCHEMAS "${DT_PROJECT}/migrations/schemas"
  var TMP_SCHEMAS "${DT_ARTEFACTS}/schemas"
  load_vars ctx_conn_migrator_pg PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER && \
  var DATABASE_URL $(database_url) && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_sqlx:default:sqlx_methods)
