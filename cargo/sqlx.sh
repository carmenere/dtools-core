function sqlx_envs() {
  local envs=(DATABASE_URL)
  echo "${envs[@]}"
}

function ctx_crate_cargo_sonar() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
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
  exec_cmd "find '$(SCHEMAS)' -type f | while read FILE; do echo -e \"cp \${FILE} '$(TMP_SCHEMAS)/'\"; cp "\${FILE}" '$(TMP_SCHEMAS)'; done"
}

function sqlx_run() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  non_empty=(TMP_SCHEMAS)
  for v in ${non_empty[@]}; do if [ -z "$(${v})" ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; fi; done
  sqlx_pre_run || return $?
  exec_cmd $(inline_vars "$(sqlx_envs)") sqlx migrate run --source "'$(TMP_SCHEMAS)'"
}

function sqlx_prepare() {
  exec_cmd cd "${DT_PROJECT_DIR}"
  exec_cmd "cargo sqlx prepare" #--workspace
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
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var SCHEMAS "${DT_PROJECT}/migrations/schemas"
  var TMP_SCHEMAS "${DT_ARTEFACTS}/schemas"
  load_vars ctx_conn_migrator_pg PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER && \
  var DATABASE_URL $(database_url) && \
  ctx_epilog ${fname}
}

DT_BINDINGS+=(ctx_sqlx:default:sqlx_methods)
