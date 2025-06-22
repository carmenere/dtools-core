function sqlx_envs() {
  local envs=(DATABASE_URL)
  echo "${envs[@]}"
}

function ctx_crate_sqlx() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  CRATE_NAME="sqlx-cli"
  CRATE_VERSION="0.8.5"
  ctx_cargo_crate ${caller} && \
  cache_ctx
}

c=ctx_crate_sqlx; add_deps "${c}" "ctx_cargo_crate"
DT_BINDINGS+=(${c}:sqlx:cargo_install_methods)

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
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var SCHEMAS "${DT_PROJECT}/migrations/schemas" && \
  var TMP_SCHEMAS "${DT_ARTEFACTS}/schemas" && \
  load_vars ctx_conn_migrator_pg PGDATABASE PGHOST PGPASSWORD PGPORT PGUSER && \
  var DATABASE_URL $(database_url) && \
  cache_ctx
}

c=ctx_sqlx; add_deps "${c}" "ctx_conn_migrator_pg"
DT_BINDINGS+=(${c}:default:sqlx_methods)
