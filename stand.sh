function dt_target() {
  # $1: name of target. Each target is a callable.
  if [ -z "$1" ]; then return 0; fi
    dt_info dt_target "Running target ${BOLD}$1${RESET} ... "
    $1
}

# Consider example: register_stand stand_host
# It will generate all necessary functions of stand_host.
# For example, for 'install_services' it generates
# function stand_host_install_services() {( stand_host_steps && run_targets "${install_services[@]}" )}
function register_stand() {
  local func stand=$1 up=$2 down=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "stand" || return $?
  tiers=($(echo "$(${up}) $(${down})"))
  for tier in ${tiers[@]}; do
    eval "function ${stand}_${tier}() {( ${stand} && run_targets "\${${tier}\[\@\]}" )}"
  done
  eval "function stand_up_${stand}() {( ${stand} && run_stand ${stand} ${up} )}"
  eval "function stand_down_${stand}() {( ${stand} && run_stand ${stand} ${down} )}"
}

# Example1: run_stand my_stand up
# Example2: run_stand my_stand down
function run_stand() {
  local fname steps stand=$1 tiers=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "stand tiers" || return $?
  dt_info ${fname} "Running stand ${BOLD}${stand}${RESET}, tiers=${BOLD}${tiers}${RESET}"
  tiers=($(${tiers}))
  for tier in ${tiers[@]}; do
    dt_info ${fname} "Running tier ${BOLD}${tier}${RESET} ... "
    for target in $(eval echo "\${${tier}[@]}"); do
      dt_target ${target}  || return $?
    done
  done
}

function run_targets() {
  local target fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "$1" ]; then return 0; fi
  for target in $@; do
    dt_target ${target} || return $?
  done
}
