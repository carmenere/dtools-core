function app_log_file() {
  if [ -z "${LOG_FILE}" ] && [ -n "${DT_LOGS}" ] && [ -n "${APP}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
}

function app_start() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "BINARY" || return $?
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  app_log_file
  if [ -n "${LOG_FILE}" ]; then export > ${LOG_FILE}; fi
  local cmd=("$(inline_envs "${_inline_envs[@]}")")
  cmd+=("${BINARY} ${OPTS} 2>&1")
  if [ -n "${LOG_FILE}" ]; then cmd+=("| tee -a ${LOG_FILE}"); fi
  cmd_exec "${cmd[@]}"
}

function app_stop() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "PKILL_PATTERN" || return $?
  err_if_empty ${fname} "APP" || return $?
  info "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  local cmd="ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  cmd_exec "${cmd}"
  info "${BOLD}done${RESET}"
}

function app_restart() { app_stop && app_start; }

app_methods=()

app_methods+=(app_stop)
app_methods+=(app_start)
app_methods+=(app_restart)