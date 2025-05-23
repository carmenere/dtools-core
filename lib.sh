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

function dt_echo() {
  # $1: command to be echoed
  >&2 echo -e "${BOLD}[dtools]${DT_ECHO_COLOR}[ECHO]${RESET} Executing command $1"
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

# Example: dt_err_if_empty $0 "conn_ctx"; exit_on_err $0 $? || return $?
function dt_err_if_empty() {
  val="$(eval echo "\$$2")"
  if [ -n "${val}" ]; then return 0; fi
  dt_error $1 "Parameter ${BOLD}$2${RESET} is empty"
}

function dt_exec() {
  cmd="$1" | sed 's/^[ \t]*//'
  if [ -z "$cmd" ]; then return 0; fi
  if [ "${DT_ECHO}" = "y" ]; then
    dt_echo "${DT_ECHO_COLOR} $cmd${RESET}"
  fi
  if ! eval "$cmd"; then dt_error $0; return 100; fi
}

# Example: exit_on_err $0 $err_code
# $0 contains name of caller function
function exit_on_err() {
  # $1: must contain $0 of caller
  # $2: error code
  # $3: error message, if it is empty use name of current function instead
  err_msg=$3
  if [ -z "${err_msg}" ]; then err_msg=$0; fi
  if [ "$2" != 0 ] ; then
    dt_error $1 "${err_msg}"
    return $2
  fi
}

# Example: ( ctx_cargo; dt_inline_envs )
function dt_inline_envs() {
  envs=()
  for env in ${_inline_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("${env}=$'${val}'"); fi
  done
  echo "${envs}"
}

# Example: ( ctx_cargo; dt_export_envs; export )
function dt_export_envs() {
  for env in ${_export_envs}; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_single_quotes "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then dt_exec_or_echo "export ${env}="${val}""; fi
  done
}

function dt_unexport_envs() {
  for env in ${_export_envs}; do
    if [ -n "${val}" ]; then dt_exec_or_echo "unset ${env}"; fi
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
  echo "Loading ${BOLD}$description${RESET} ... "
  for file in "$dir"/*.sh; do
    if [ "$(basename "$file")" != "rc.sh"  ]; then
      echo -n "Sourcing "$(dirname "$file")/${BOLD}$(basename "$file")${RESET}" ..."
      . "$file"
      echo " done.";
    fi
  done
}
function dt_apply_ctx() {
  ctx="$1"
  #  if ctx is empty, it means nothing to apply
  $ctx; exit_on_err $0 $? "Cannot apply context '${BOLD}${ctx}${RESET}'." || return $?
}

function dt_exec_or_echo() {
  cmd="$1"
  mode="$2"
  if [ -z "${cmd}" ]; then
    dt_error $0 "cmd is empty cmd='${cmd}'."; return 99
  fi
  if [ "$mode" = "echo" ]; then
    echo "${cmd}"
  else
    dt_exec "${cmd}"
  fi
}

function dt_run_targets() {
  if [ -z "$1" ]; then return 0; fi
  targets=("$@")
  for target in $@; do
    dt_target $target; exit_on_err $0 $? || return $?
  done
}

# Consider function docker_build()
# dt_impl ctx_conn_docker_pg_admin pg docker_methods
# will generate function docker_build_pg() {( ctx_conn_docker_pg_admin && docker_build_pg )}
function dt_impl() {
  local ctx=$1; dt_err_if_empty $0 "ctx"; exit_on_err $0 $? || return $?
  local suffix=$2; dt_err_if_empty $0 "suffix"; exit_on_err $0 $? || return $?
  shift; shift
  local methods=("$@"); dt_err_if_empty $0 "methods"; exit_on_err $0 $? || return $?
  for method in $methods; do
    eval "function ${method}_${suffix}() {( mode=\$1; $ctx && ${method} \${mode} )}"
  done
}

function dt_sleep_5() {
  sleep 5
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

# Example: dt_deploy stand_host
function dt_deploy_stand() {
  local stand=$1; dt_err_if_empty $0 "stand"; exit_on_err $0 $? || return $?
  dt_info "Deploying stand ${BOLD}${stand}${RESET} ... "
  $stand
  for step in ${steps}; do
    dt_info "Running step ${BOLD}${CYAN}$step${RESET} ... "
    for target in $(eval echo "\${${step}[@]}"); do
      dt_target $target; exit_on_err $0 $? || return $?
    done
  done
}

function dt_defaults() {
  export DT_PROFILES=("dev")
  export DT_ECHO="y"
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
  . "${DT_LOCALS}/rc.sh"
}
