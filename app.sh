app_envs() { echo "$(inline_vars "${APP_ENVS}")"; }

function app_log_file() {
  if [ -z "${LOG_FILE}" ] && [ -n "${DT_LOGS}" ] && [ -n "${APP}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
}

function app_start() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "BINARY APP" || return $?
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  app_log_file
  local cmd=("$(inline_envs "${_inline_envs[@]}")")
  cmd_exec $(app_envs) ${BINARY} ${OPTS} 2\>\&1 \| tee -a ${LOG_FILE}
}

function stop_app() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "APP PKILL_PATTERN" || return $?
  dt_info ${fname} "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  cmd_exec "ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_info ${fname} "${BOLD}done${RESET}"
}

function app_restart() { stop_app && app_start; }

function app_methods() {
  local methods=()
  methods+=(stop_app)
  methods+=(app_start)
  methods+=(app_restart)
  echo "${methods[@]}"
}
