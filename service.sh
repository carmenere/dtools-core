function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

function service_stop() {
  (
    local mode=$1
    dt_exec_or_echo "${SERVICE_STOP}" $mode
  )
}

function service_start() {
  (
    local mode=$1
    dt_exec_or_echo "${SERVICE_START}" $mode
  )
}

function service_restart() {
  service_stop && service_start
}

function service_prepare() {
  dt_exec_or_echo "${SERVICE_PREPARE}" $mode
}

function service_install() {
  dt_exec_or_echo "${SERVICE_INSTALL}" $mode
}

function service_lsof() {
  dt_exec_or_echo "${SERVICE_LSOF}" $mode
}

service_methods=()

service_methods+=(service_start)
service_methods+=(service_stop)
service_methods+=(service_restart)
service_methods+=(service_prepare)
service_methods+=(service_install)
service_methods+=(service_lsof)

function console_log_file() {
  if [ -z "${LOG_FILE}" ] && [ -n "${DT_LOGS}" ] && [ -n "${APP}" ]; then
    LOG_FILE="${DT_LOGS}/${APP}.logs"
  fi
  if [ -n "${LOG_FILE}" ] && [ ! -d "$(dirname ${LOG_FILE})" ]; then mkdir -p $(dirname "${LOG_FILE}"); fi
}

function console_start() {
  mode=$1
  dt_err_if_empty $0 "BINARY"; exit_on_err $0 $? || return $?
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  console_log_file
  if [ -n "${LOG_FILE}" ]; then export > ${LOG_FILE}; fi
  echo "_inline_envs=${_inline_envs}"
  echo "TTX_PGPORT=${TTX_PGPORT}"
  cmd=("$(dt_inline_envs)")
  cmd+=("${BINARY} ${OPTS} 2>&1")
  if [ -n "${LOG_FILE}" ]; then cmd+=("| tee -a ${LOG_FILE}"); fi
  dt_exec_or_echo "${cmd}" ${mode}
}

function console_stop() {
  mode=$1
  dt_err_if_empty $0 "PKILL_PATTERN"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "APP"; exit_on_err $0 $? || return $?
  dt_info "Sending signal 'KILL' to ${BOLD}${APP}${RESET} ..."
  cmd="ps -A -o pid,args | grep -v grep | grep '${PKILL_PATTERN}' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_exec_or_echo "${cmd}" ${mode}
  dt_info "${BOLD}done${RESET}"
}

function console_restart() {
  console_stop && console_start
}

console_methods=()

console_methods+=(console_stop)
console_methods+=(console_start)
console_methods+=(console_restart)

# MacOS
function brew_list_services() { brew services list
}

# Linux, systemd
function systemctl_list_services() { systemctl list-units --type service | cat
}
# lists all installed unit files
function systemctl_list_unit_files() { systemctl list-unit-files | cat
}
# lists units that systemd currently has in memory
function systemctl_list_units() { systemctl list-units | cat
}
# filter by type
function systemctl_list_units_automount() { systemctl list-units --type automount | cat
}
function systemctl_list_units_device() { systemctl list-units --type device | cat
}
function systemctl_list_units_mount() { systemctl list-units --type mount | cat
}
function systemctl_list_units_path() { systemctl list-units --type path | cat
}
function systemctl_list_units_scope() { systemctl list-units --type scope | cat
}
function systemctl_list_units_service() { systemctl list-units --type service | cat
}
function systemctl_list_units_slice() { systemctl list-units --type slice | cat
}
function systemctl_list_units_socket() { systemctl list-units --type socket | cat
}
function systemctl_list_units_swap() { systemctl list-units --type swap | cat
}
function systemctl_list_units_target() { systemctl list-units --type target | cat
}
function systemctl_list_units_timer() { systemctl list-units --type timer | cat
}

