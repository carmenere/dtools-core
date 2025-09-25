function sqlx_run() {(
  set -eu
  local fname=sqlx_run
  . "${DT_VARS}/sqlx/$1.sh"
  set -o pipefail
  if [ -n "${SQLX_RUN_HOOK}" ] && declare -f "${SQLX_RUN_HOOK}" >/dev/null 2>&1; then
    exec_cmd ${SQLX_RUN_HOOK}
    return $?
  fi

  if [ -z "${TMP_SCHEMAS}" ]; then dt_error ${fname} "Var ${BOLD}${TMP_SCHEMAS}${RESET} is empty"; fi
  if [ -z "${SCHEMAS}" ]; then dt_error ${fname} "Var ${BOLD}${SCHEMAS}${RESET} is empty"; fi
  exec_cmd rm -rf "${TMP_SCHEMAS}"
  exec_cmd mkdir -p "${TMP_SCHEMAS}"
  exec_cmd "find '${SCHEMAS}' -type f | while read FILE; do echo -e \"cp \${FILE} '${TMP_SCHEMAS}/'\"; cp "\${FILE}" '${TMP_SCHEMAS}'; done"
  exec_cmd "$(inline_envs)" sqlx migrate run --source "'${TMP_SCHEMAS}'"
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_sqlx() {
  local methods=()
  methods+=(sqlx_run)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_sqlx"
