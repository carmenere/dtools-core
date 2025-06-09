# All functions "dt_error", "dt_warning", "dt_info" and "dt_debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message
function dt_error() {
  if [ "${DT_SEVERITY}" -ge 0 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR][$1]${RESET} $2"
  fi
}

function dt_warning() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING][$1]${RESET} $2"
  fi
}

function dt_info() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO][$1]${RESET} $2"
  fi
}

function dt_debug () {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG][$1]${RESET} $2"
  fi
}

function severity_error() { DT_SEVERITY=0; }
function severity_warning() { DT_SEVERITY=1; }
function severity_info() { DT_SEVERITY=2; }
function severity_debug() { DT_SEVERITY=3; }

# Example: dt_err_if_empty ${fname} ${fname} "FOO" || return $?
# where FOO is a name of some variable.
# $1: must contain $0 of caller
# $2: must contain name of variable
function dt_err_if_empty() {
  local fname=$1
  local var=$2
  if [ -z "${fname}" ]; then dt_error "dt_err_if_empty" "Parameter ${BOLD}fname${RESET} must be provided"; return 55; fi
  if [ -z "${var}" ]; then dt_error "dt_err_if_empty" "Parameter ${BOLD}${var}${RESET} must be provided"; return 55; fi
  local val="$(eval echo "\$$var")"
  if [ -z "${val}" ]; then
    dt_error ${fname} "Parameter ${BOLD}${var}${RESET} is empty"
    return 77
  fi
}

function dt_inline_envs() {
  local envs val
  envs=()
  for env in "$@"; do
    if [ -z "$env" ]; then continue; fi
    val=$(dt_escape_quote "$(eval echo "\$$env")")
    if [ -n "${val}" ]; then envs+=("${env}=$'${val}'"); fi
  done
  echo "${envs[@]}"
}

function dt_escape_quote() {
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

function dt_exec () {
  local fname cmd
  fname=$1; shift
  cmd=$(echo "$@" | sed 's/^[ \t]*//')
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
      >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][ECHO][EXEC][$fname]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "${cmd}" || return $?
  fi
}

function dt_echo() {
  local fname saved_DT_DRYRUN saved_DT_ECHO
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  saved_DT_DRYRUN=${DT_DRYRUN}
  saved_DT_ECHO=${DT_DRYRUN}
  dt_dryrun_on
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  eval "$@" || return $?
  DT_ECHO_STDOUT="n"
  DT_DRYRUN=${saved_DT_DRYRUN}
  DT_ECHO=${saved_DT_ECHO}
}

function dt_exists() {
  local fname entity value err
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  entity=$1
  value=$2
  err=$3
  if [ "$err" = 0 ]; then
    dt_info ${fname} "${entity} ${BOLD}${value} exists${RESET}, err=${err}."
    return 0
  else
    dt_info ${fname} "${entity} ${BOLD}${value} doesn't exist${RESET}, err=${err}."
    return 1
  fi
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

function dt_sleep_5() {
  dt_exec ${fname} "sleep 5"
}

function dt_sleep_1() {
  dt_exec ${fname} "sleep 1"
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
  # Cache for ctxes
  export DT_CTXES=${DT_LOGS}/ctxes
  if [ ! -d "${DT_LOGS}" ]; then mkdir -p ${DT_LOGS}; fi
  if [ ! -d "${DT_REPORTS}" ]; then mkdir -p ${DT_REPORTS}; fi
  if [ ! -d "${DT_TOOLCHAIN}" ]; then mkdir -p ${DT_TOOLCHAIN}; fi
  # Delete all ctxes every time ". ./dtools/rc.sh" is called
  rm -rf ${DT_CTXES} && mkdir -p ${DT_CTXES}
}

# DT_SEVERITY >= 4 for dumps!
function dt_defaults() {
  export DT_DRYRUN="n"
  export DT_PROFILES=(dev)
  export DT_SEVERITY=4
  export DT_ECHO="y"
  export DT_ECHO_STDOUT="n"
  export DT_ECHO_COLOR="${YELLOW}"
}

function dt_init() {
  dt_paths
  . "${DT_CORE}/colors.sh"
  dt_defaults
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh"; fi
  . "${DT_CORE}/rc.sh"
  . "${DT_TOOLS}/rc.sh"
  . "${DT_STANDS}/rc.sh"

}

# Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
# will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
function dt_register() {
  local fname ctx suffix methods method
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  suffix=$2; dt_err_if_empty ${fname} "suffix" || return $?
  methods=($(echo "$3"))
  for method in ${methods[@]}; do
    eval "function ${method}_${suffix}() {( . ${ctx} && ${method} )}" || return $?
  done
}

function var_prf() {
  echo "$1__"
}

# get var
function gvar() {
  var=$(var_prf $1)$2
  val=$(eval echo "\${${${var}}}")
  echo "${val}"
}

# set var
function var() {
  local fname ctx var val parent_val
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  var=$2; dt_err_if_empty ${fname} "var" || return $?
  val=$3
  var=$(var_prf ${ctx})${var}
  parent_val=$(eval echo "\${${var}}")
  dt_debug ${fname} "export var=${var}; val=${parent_val}, new_val=${val}"
  if [ -z "${parent_val}" ]; then
    eval "${var}=\"${val}\""
  fi
  export ${var}
}

