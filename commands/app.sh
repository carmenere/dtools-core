function app_start() {(
  local non_empty fname=$(fname "${FUNCNAME[0]}" "$0")
  set -eu
  . "${DT_VARS}/apps/$1.sh"
  non_empty=(APP BINARY LOG_FILE)
  for v in ${non_empty[@]}; do if [ -z $(eval echo "\$${v}") ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; return 99; fi; done
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
  exec_cmd "$(inline_envs)" ${BINARY} ${OPTS} 2\>\&1 \| tee -a ${LOG_FILE}
)}

function app_stop() {(
  local non_empty fname=$(fname "${FUNCNAME[0]}" "$0")
  set -eu
  . "${DT_VARS}/apps/$1.sh"
  non_empty=(APP PKILL_PATTERN)
  for v in ${non_empty[@]}; do if [ -z $(eval echo "\$${v}") ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; return 99; fi; done
  dt_info ${fname} "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  exec_cmd "ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_info ${fname} "${BOLD}done${RESET}"
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_app() {
  local methods=()
  methods+=(app_stop)
  methods+=(app_start)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_app"
