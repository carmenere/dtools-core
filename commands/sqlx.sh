function sqlx_run() {(
  set -eu
  local fname=sqlx_run
  . "${DT_VARS}/sqlx/$1.sh"
  if [ -z "${TMP_SCHEMAS}" ]; then dt_error ${fname} "Var ${BOLD}${TMP_SCHEMAS}${RESET} is empty"; fi
  if [ -z "${SCHEMAS}" ]; then dt_error ${fname} "Var ${BOLD}${SCHEMAS}${RESET} is empty"; fi
  rm -rf "${TMP_SCHEMAS}"
  mkdir -p "${TMP_SCHEMAS}"
  exec_cmd "find '${SCHEMAS}' -type f | while read FILE; do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done"
  exec_cmd "$(inline_envs)" sqlx migrate run --source "'${TMP_SCHEMAS}'"
)}

function sqlx_prepare() {(
  set -eu
  . "${DT_VARS}/sqlx/$1.sh"
  exec_cmd cd "${MANIFEST_DIR}"
  exec_cmd "$(inline_envs)" cargo sqlx prepare #--workspace
)}

##################################################### AUTOCOMPLETE #####################################################
function methods_sqlx() {
  local methods=()
  methods+=(sqlx_pre_run)
  methods+=(sqlx_run)
  methods+=(sqlx_prepare)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_sqlx)
DT_AUTOCOMPLETIONS["methods_sqlx"]=""
