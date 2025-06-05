# All functions "dt_error", "dt_warning", "dt_info" and "dt_debug" have the same signature:
#   $1: must contain $0 of caller
#   $2: must contain err message
function dt_error() {
  if [ "${DT_SEVERITY}" -ge 0 ]; then
    >&2 echo -e "${RED}${BOLD}[dtools][ERROR]${RESET}[$1] $2"
  fi
}

function dt_warning() {
  if [ "${DT_SEVERITY}" -ge 1 ]; then
    >&2 echo -e "${CYAN}${BOLD}[dtools][WARNING]${RESET}[$1] $2"
  fi
}

function dt_info() {
  if [ "${DT_SEVERITY}" -ge 2 ]; then
    >&2 echo -e "${GREEN}${BOLD}[dtools][INFO]${RESET}[$1] $2"
  fi
}

function dt_debug () {
  if [ "${DT_SEVERITY}" -ge 3 ]; then
    >&2 echo -e "${MAGENTA}${BOLD}[dtools][DEBUG]${RESET}[$1] $2"
  fi
}

# Example: dt_err_if_empty ${fname} ${fname} "FOO"; err=$?; if [ "${err}" != 0 ]; then return ${err}; fi
# where FOO is a name of some variable.
# $1: must contain $0 of caller
# $2: must contain name of variable
function dt_err_if_empty() {
  local fname=$1
  local var=$2
  local local val="$(eval echo "\$$var")"
  if [ -z "${val}" ]; then
    dt_error ${fname} "Parameter ${BOLD}${var}${RESET} is empty"
    return 77
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
    eval "${cmd}"; err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  fi
}

function dt_echo() {
  local fname saved_DT_DRYRUN saved_DT_ECHO
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  saved_DT_DRYRUN=${DT_DRYRUN}
  saved_DT_ECHO=${DT_DRYRUN}
  dt_dryrun_on
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  eval "$@"; err=$?; if [ "${err}" != 0 ]; then dt_error ${fname} "err=${err}"; return ${err}; fi
  DT_ECHO_STDOUT="n"
  DT_DRYRUN=${saved_DT_DRYRUN}
  DT_ECHO=${saved_DT_ECHO}
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
  dt_exec "sleep 5"
}

function dt_sleep_1() {
  dt_exec "sleep 1"
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
  export DT_SEVERITY=4
  export DT_ECHO="y"
  export DT_ECHO_STDOUT="n"
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
