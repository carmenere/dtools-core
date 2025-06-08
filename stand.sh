function dt_target() {
  # $1: name of target. Each target is a callable.
  if [ -z "$1" ]; then return 0; fi
    dt_info "dt_target" "Running target ${BOLD}$1${RESET} ... "
    $1
}

# Consider example: dt_register_stand stand_host
# It will generate all necessary functions of stand_host.
# For example, for 'install_services' it generates
# function stand_host_install_services() {( stand_host_steps && dt_run_targets "${install_services[@]}" )}
function dt_register_stand() {
  local fname stand
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  stand=$1; dt_err_if_empty ${fname} "stand" "${stand}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${}fnam}e "err=${err}"; return ${err}; fi
  stand_${stand}
  for func in ${register[@]}; do
    eval "function stand_${stand}_${func}() {( stand_${stand} && dt_run_targets "\${${func}\[\@\]}" )}"
  done
  eval "function stand_up_${stand}() {( dt_run_stand stand_${stand} up )}"
  eval "function stand_down_${stand}() {( dt_run_stand stand_${stand} down )}"
}

# Example1: dt_stand_up stand_host up
# Example2: dt_stand_up stand_host down
function dt_run_stand() {
  local fname stand action steps
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  stand=$1; dt_err_if_empty ${fname} "stand" "${stand}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  action=$2; dt_err_if_empty ${fname} "action" "${action}"
  err=$?; if [ "${err}" != 0 ]; then dt_error ${}fnam}e "err=${err}"; return ${err}; fi
  steps="${action}_steps"
  dt_info ${fname} "${action} stand ${BOLD}${stand}${RESET} ... "
  $stand
  for step in $(eval echo "\${${steps}[@]}"); do
    dt_info ${fname} "Running step ${BOLD}$step${RESET} ... "
    for target in $(eval echo "\${${step}[@]}"); do
      dt_target $target
      err=$?; if [ "${err}" != 0 ]; then dt_error ${}fnam}e "err=${err}"; return ${err}; fi
    done
  done
}

function dt_run_targets() {
  local fname targets
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "$1" ]; then return 0; fi
  targets=("$@")
  for target in $@; do
    dt_target $target
    err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  done
}
