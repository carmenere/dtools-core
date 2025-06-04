function dt_warning() {
  # $1: info message
  >&2 echo -e "${BOLD}[dtools]${MAGENTA}[WARNING]${RESET} $1"
}

function dt_error() {
  # $1: must contain $0 of caller
  # $2: must contain err message
  >&2 echo -e "${BOLD}[dtools]${RED}[ERROR]<in function $1>${RESET} $2"
}

function dt_info() {
  # $1: info message
  >&2 echo -e "${BOLD}[dtools]${GREEN}[INFO]${RESET} $1"
}

function dt_debug() {
  # $1: debug message
  >&2 echo -e "${BOLD}${MAGENTA}[dtools][DEBUG]${RESET} $1"
}

function dt_target() {
  # $1: name of target. Each target is a callable.
  if [ -z "$1" ]; then return 0; fi
    dt_info "Running target ${BOLD}${GREEN}$1${RESET} ... "
    $1
}

# Example: dt_err_if_empty "var_name" "${var_name}"; exit_on_err ${fname} $? || return $?
function dt_err_if_empty() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local parameter=$1
  local val=$2
  if [ -z "${val}" ]; then
    dt_error ${fname} "Parameter ${BOLD}${parameter}${RESET} is empty"
    return 77
  fi
}

## Example: dt_err_if_empty "var_name" "${var_name}"; exit_on_err ${fname} $? || return $?
#function dt_err_if_empty() {
#  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
#  local parameter=$1
#  local val="$(eval echo "\$${parameter}")"
#  if [ -z "${val}" ]; then
#    dt_error ${fname} "Parameter ${BOLD}${parameter}${RESET} is empty"
#    return 77
#  fi
#}

# Example: exit_on_err ${fname} $err_code
# $0 contains name of caller function
function exit_on_err() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  # $1: must contain $0 of caller
  # $2: error code
  # $3: error message, if it is empty use name of current function instead
  local err_msg=$3
  if [ -z "${err_msg}" ]; then err_msg=${fname}; fi
  if [ "$2" != 0 ] ; then
    dt_error $1 "${err_msg}"
    return $2
  fi
}

function dt_inline_envs() {
  local envs=()
  for env in "$@"; do
    if [ -z "$env" ]; then continue; fi
    local val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("${env}=$'${val}'"); fi
  done
  echo "${envs[@]}"
}

# Example: ( ctx_cargo; dt_export_envs; export )
function dt_export_envs() {
  for env in ${_export_envs[@]}; do
    if [ -z "$env" ]; then continue; fi
    local val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then
      dt_exec "export ${env}="${val}""
    fi
  done
}

function dt_unexport_envs() {
  for env in ${_export_envs[@]}; do
    dt_exec "unset ${env}"
  done
}

function dt_escape_single_quotes() {
  echo "$1" | sed -e "s/'/\\\\'/g"
}

function dt_rc_load() {
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  echo -e "Loading ${BOLD}$description${RESET} ... "
  for file in "$dir"/*.sh; do
    if [ "$(basename "$file")" != "rc.sh"  ]; then
      echo -e -n "Sourcing "$(dirname "$file")/${BOLD}$(basename "$file")${RESET}" ..."
      . "$file" || return 55
      echo "done.";
    fi
  done
}
function dt_apply_ctx() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx="$1"
  #  if ctx is empty, it means nothing to apply
  $ctx; exit_on_err ${fname} $? "Cannot apply context '${BOLD}${ctx}${RESET}'." || return $?
}

function dt_exec() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local cmd=$(echo "$@" | sed 's/^[ \t]*//')
  if [ -z "${cmd}" ]; then
    dt_error ${fname} "The command is empty cmd='${cmd}'."; return 99
  fi
  if [ "${DT_DRYRUN}" = "y" ]; then
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools][DRYRUN]${RESET}"
      >&2 echo -e "${cmd}"
    fi
    if [ "${DT_ECHO_STDOUT}" = "y" ]; then
      echo -e "${cmd}"
    fi
  else
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools]${DT_ECHO_COLOR}[ECHO][EXEC]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "${cmd}"; exit_on_err ${fname} $? || return $?
  fi
}

function dt_echo() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local saved_DT_DRYRUN=${DT_DRYRUN}
  local saved_DT_ECHO=${DT_DRYRUN}
  dt_dryrun_on
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  eval "$@"; err=$?
  DT_ECHO_STDOUT="n"
  DT_DRYRUN=${saved_DT_DRYRUN}
  DT_ECHO=${saved_DT_ECHO}
  exit_on_err ${fname} ${err} || return $?
}

function dt_exists() {
  entity=$1
  value=$2
  err=$3
  if [ "$err" = 0 ]; then
    dt_info "${entity} ${BOLD}${value} exists${RESET}."
    return 0
  else
    dt_info "${entity} ${BOLD}${value} doesn't exist${RESET}."
    return 1
  fi
}

function dt_run_targets() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ -z "$1" ]; then return 0; fi
  local targets=("$@")
  for target in $@; do
    dt_target $target; exit_on_err ${fname} $? || return $?
  done
}

function dt_dryrun_commands_only_on() {
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  dt_dryrun_on
}

function dt_dryrun_commands_only_off() {
  DT_ECHO_STDOUT="n"
  DT_ECHO="y"
  dt_dryrun_off
}

function dt_dryrun_on() {
  DT_DRYRUN="y"
}

function dt_dryrun_off() {
  DT_DRYRUN="n"
}

function is_function() {
  type "$1" | sed "s/$1//" | grep -qwi function
}

function dt_fname() {
  if [ -n "$1" ]; then echo "$1"; else echo "$2"; fi;
}

# Consider function docker_build()
# dt_register ctx_conn_docker_pg_admin pg docker_methods
# will generate function docker_build_pg() {( ctx_conn_docker_pg_admin && docker_build_pg )}
function dt_register() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local ctx=$1; dt_err_if_empty "ctx" "${ctx}"; exit_on_err ${fname} $? || return $?
  local suffix=$2; dt_err_if_empty "suffix" "${suffix}"; exit_on_err ${fname} $? || return $?
  shift 2
  local methods=("$@"); dt_err_if_empty "methods" "${methods}"; exit_on_err ${fname} $? || return $?
  for method in ${methods[@]}; do
    local func=${method}_${suffix}
    eval "function ${func}() {( ${ctx} && ${method} )}"
  done
}

# Consider example: dt_register_stand stand_host
# It will generate all necessary functions of stand_host.
# For example, for 'install_services' it generates
# function stand_host_install_services() {( stand_host_steps && dt_run_targets "${install_services[@]}" )}
function dt_register_stand() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local stand=$1; dt_err_if_empty "stand" "${stand}"; exit_on_err ${fname} $? || return $?
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
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local stand=$1; dt_err_if_empty "stand" "${stand}"; exit_on_err ${fname} $? || return $?
  local action=$2; dt_err_if_empty "action" "${action}"; exit_on_err ${fname} $? || return $?
  local steps="${action}_steps"
  dt_info "${action} stand ${BOLD}${stand}${RESET} ... "
  $stand
  for step in $(eval echo "\${${steps}[@]}"); do
    dt_info "Running step ${BOLD}${CYAN}$step${RESET} ... "
    for target in $(eval echo "\${${step}[@]}"); do
      dt_target $target; exit_on_err ${fname} $? || return $?
    done
  done
}

function dt_sleep_5() {
  dt_exec "sleep 5"
}

function dt_sleep_1() {
  dt_exec "sleep 1"
}

# Example: dt_var ctx_name var_name value
function dt_var() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  local var=$1; dt_err_if_empty "var" "${var}"; exit_on_err ${fname} $? || return $?
  shift
  local val="$@"; dt_err_if_empty "val" "${val}"; exit_on_err ${fname} $? || return $?
  echo "CTX=$CTX"
  echo "var=$var"
  echo "val=$val"
  eval "ctx_${CTX}+=(${var})" && \
  eval "${CTX}_${var}=\"${val}\""
}

function xxx() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  CTX=$0
  eval "ctx_${CTX}=()"
  dt_var A dsg dfg dg df g; exit_on_err ${fname} $? || return $?
  dt_var B 123 4; exit_on_err ${fname} $? || return $?
}

function dt_merge() {
  echo "$@"
  OPTS=$(getopt -o d:v:c: --long dst:,vars:,ctxes: -- "$@")
  # vars - contains array with vars names
  # ctxes - contains array of ctxes
  # dst - is a new ctx, where we want merge vars
  echo "OPTS=${OPTS}"
  if [ $? -ne 0 ]; then
    dt_error $0 "Failed to parse options" >&2
    return 99
  fi
  eval set -- "${OPTS}"
  local ctxes vars ctx val dst
  while true; do
    case "$1" in
      --vars) vars="${vars}$2"; shift 2;;
      --dst) dst="$2"; shift 2;;
      --ctxes) ctxes="${ctxes}$2"; shift 2;;
      --) shift; break;;
      *) echo "Unknown option $1"; return 99;;
    esac
  done
  vars=($(echo "$vars" | tr ' ' '\n'))
  ctxes=($(echo "$ctxes" | tr ' ' '\n'))
  for var in ${vars[@]}; do
    for ctx in ${ctxes[@]}; do
      val="$(eval echo "\$${ctx}_${var}")"
      if [ -z "${val}" ]; then continue; fi
      eval ${dst}_${var}="${val}"
    done
  done
}

function dt_paths() {
  if [ -z "${DT_DTOOLS}" ]; then DT_DTOOLS="$(pwd)"; fi

  # Paths that depend on DT_DTOOLS
  export DT_PROJECT=$(realpath "${DT_DTOOLS}"/..)
  export DT_ARTEFACTS="${DT_DTOOLS}/.artefacts"
  export DT_CORE=${DT_DTOOLS}/core
  export DT_LOCALS=${DT_DTOOLS}/locals
  export DT_STANDS=${DT_DTOOLS}/stands
  export DT_TOOLS=${DT_DTOOLS}/tools

  # Paths that depend on DT_ARTEFACTS
  export DT_LOGS="${DT_ARTEFACTS}/logs"
  export DT_REPORTS="${DT_ARTEFACTS}/reports"
  export DT_TOOLCHAIN=${DT_ARTEFACTS}/toolchain
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
}

function dt_defaults() {
  export DT_DRYRUN="n"
  export DT_PROFILES=("dev")
  export DT_ECHO="y"
  export DT_ECHO_STDOUT="n"
  export DT_DEBUG="n"
  export DT_ECHO_COLOR="${YELLOW}"
}

function dt_init() {
  dt_paths
  . "${DT_CORE}/colors.sh"
  dt_defaults
  . "${DT_CORE}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
  . "${DT_STANDS}/rc.sh"
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh"; fi
}
