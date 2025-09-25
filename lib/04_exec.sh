export DT_DRYRUN="n"
export DT_ECHO="y"
export DT_ECHO_COLOR="${YELLOW}"

# For compatibility with "docker_exec", but we must DROP FIRST ARG for "exec_cmd"
host_exec() { shift; exec_cmd $@; }

set_dryrun_off() { DT_DRYRUN="n"; }
set_dryrun_on() { DT_DRYRUN="y"; }

# First arg for docker exec signature compatability
exec_cmd () {
  local cmd="$@" fname="exec_cmd"
  if [ -z "${cmd}" ]; then
    dt_error ${fname} "The command is empty cmd='${cmd}'."
    return 99
  fi
  if [ "${DT_DRYRUN}" = "y" ]; then
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools][DT_DRYRUN]${RESET}"
      >&2 echo -e "${cmd}"
    fi
  else
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools][DT_ECHO][$(date +"%Y-%m-%d %H:%M:%S")][exec_cmd]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "$(echo -e "${cmd}")" || return $?
  fi
}
