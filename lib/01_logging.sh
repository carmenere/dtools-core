# By default: DT_SEVERITY >= 3
logging_init() {
  export DT_SEVERITY=3
  logging_paths
  reset_err_cnt
}

logging_paths() {
  export DT_ERR_COUNTER_PATH="/tmp/dt_err_counter"
  export DT_ERR_COUNTER=0
}

get_err_cnt() { echo "$(. "${DT_ERR_COUNTER_PATH}" && echo "${DT_ERR_COUNTER}")"; }
inc_err_cnt() { DT_ERR_COUNTER=$(($(get_err_cnt)+1)); $(save_err_cnt); }
reset_err_cnt() { DT_ERR_COUNTER=0; $(save_err_cnt); }
save_err_cnt() { echo "DT_ERR_COUNTER=${DT_ERR_COUNTER}" > ${DT_ERR_COUNTER_PATH}; }

# All functions "dt_log", "error", "warning", "dt_info" and "debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message

dt_error() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$1]${RESET} $2"
  fi
  inc_err_cnt
}

dt_warning() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$1]${RESET} $2"
  fi
}

dt_info() {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
  fi
}

dt_debug () {
  if [ "${DT_SEVERITY}" -ge 4 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$1]${RESET} $2"
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
  for var in ${vars[@]}; do
    val="$(eval echo "\$${var}")"
    if [ -z "${val}" ]; then
      dt_error "err_if_empty in ${fname}" "Parameter ${BOLD}${var}${RESET} is empty"
      return 77
    fi
  done
}