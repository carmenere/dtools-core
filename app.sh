function ctx_app() {
  APP="tetrix-api"
  BINARY=
  PKILL_PATTERN="${BINARY}"
  app_envs=()
}

function app_log_file() {
  if [ -z "${LOG_FILE}" ] && [ -n "${DT_LOGS}" ] && [ -n "${APP}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
}

function app_start() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "BINARY" || return $?
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  app_log_file || return $?
  if [ -n "${LOG_FILE}" ]; then export > ${LOG_FILE}; fi
  cmd=("$(dt_inline_envs "${app_envs[@]}")")
  cmd+=("${BINARY} ${OPTS} 2>&1")
  if [ -n "${LOG_FILE}" ]; then cmd+=("| tee -a ${LOG_FILE}"); fi
  dt_exec ${fname} "${cmd[@]}"
}

function app_stop() {
  local fname cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PKILL_PATTERN" || return $?
  dt_err_if_empty ${fname} "APP" || return $?
  dt_info ${fname} "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  cmd="ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_exec ${fname} "${cmd}"
  dt_info ${fname} "${BOLD}done${RESET}"
}

function app_restart() { app_stop && app_start; }

app_methods=()

app_methods+=(app_stop)
app_methods+=(app_start)
app_methods+=(app_restart)