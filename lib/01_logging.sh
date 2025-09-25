# By default: DT_SEVERITY >= 3
logging_init() {
  if [ -z "${DT_SEVERITY+set_or_notnull}" ]; then
    DT_SEVERITY=3
  fi
  export DT_SEVERITY
}

# All functions "dt_log", "error", "warning", "dt_info" and "debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message

dt_error() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$(date +"%Y-%m-%d %H:%M:%S")][$1]${RESET} $2"
  fi
  inc_err_cnt
}

dt_warning() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$(date +"%Y-%m-%d %H:%M:%S")][$1]${RESET} $2"
  fi
}

dt_info() {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$(date +"%Y-%m-%d %H:%M:%S")][$1]${RESET} $2"
  fi
}

dt_debug () {
  if [ "${DT_SEVERITY}" -ge 4 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$(date +"%Y-%m-%d %H:%M:%S")][$1]${RESET} $2"
  fi
}

set_severity_error() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=1; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_warning() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=2; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_info() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=3; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }
set_severity_debug() { local fname=$(fname "${FUNCNAME[0]}" "$0"); DT_SEVERITY=4; dt_log ${fname} "DT_SEVERITY=${DT_SEVERITY}"; }

severity() { echo "${DT_SEVERITY}"; }

err_if_empty() {
  local var vars val fname=$1 vars=($(echo $2))
  if [ -z "${fname}" ]; then dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}fname${RESET} must be provided"; return 55; fi
  if [ -z "${vars}" ]; then dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}vars${RESET} must be provided"; return 55; fi
  for var in "${vars[@]}"; do
    val="$(eval echo "\$${var}")"
    if [ -z "${val}" ]; then
      dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}${var}${RESET} is empty"
      return 77
    fi
  done
}