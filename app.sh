function app_log_file() {
  if [ -z "${LOG_FILE}" ] && [ -n "${DT_LOGS}" ] && [ -n "${APP}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
}

function app_start() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty "BINARY" "${BINARY}"; exit_on_err ${fname} $? || return $?
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  app_log_file
  if [ -n "${LOG_FILE}" ]; then export > ${LOG_FILE}; fi
  local cmd=("$(dt_inline_envs "${_inline_envs[@]}")")
  cmd+=("${BINARY} ${OPTS} 2>&1")
  if [ -n "${LOG_FILE}" ]; then cmd+=("| tee -a ${LOG_FILE}"); fi
  dt_exec "${cmd[@]}"
}

function app_stop() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty "PKILL_PATTERN" "${PKILL_PATTERN}"; exit_on_err ${fname} $? || return $?
  dt_err_if_empty "APP" "${APP}"; exit_on_err ${fname} $? || return $?
  dt_info "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  local cmd="ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_exec "${cmd}"
  dt_info "${BOLD}done${RESET}"
}

function app_restart() { app_stop && app_start; }

app_methods=()

app_methods+=(app_stop)
app_methods+=(app_start)
app_methods+=(app_restart)