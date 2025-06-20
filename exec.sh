dryrun_off() { DT_DRYRUN="n"; }
dryrun_on() { DT_DRYRUN="y"; }

exec_cmd () {
  local cmd="$@" fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${cmd}" ]; then
    dt_error ${fname} "The command is empty cmd='${cmd}'."
    return 99
  fi
  if [ "${DT_DRYRUN}" = "y" ]; then
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}[dtools][DT_DRYRUN]${RESET}"
      >&2 echo -e "${cmd}"
    fi
    if [ "${DT_ECHO_STDOUT}" = "y" ]; then
      echo -e "${cmd}"
    fi
  else
    if [ "${DT_ECHO}" = "y" ]; then
      >&2 echo -e "${BOLD}${DT_ECHO_COLOR}[dtools][DT_ECHO][exec_cmd]${RESET}"
      >&2 echo -e "${DT_ECHO_COLOR}${cmd}${RESET}"
    fi
    eval "$(echo -e "${cmd}")" || return $?
  fi
}

docker_exec_cmd() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "${DT_CTX}" ]; then
    dt_error ${fname} "Context ${BOLD}DT_CTX${RESET} is empty"
    return 99
  fi
  mref=$(get_method ${DT_CTX} docker_exec)
  exec_cmd "$(${mref}) sh << EOF\n$@\nEOF"
}

cmd_echo() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local saved_DRYRUN saved_ECHO
  saved_DRYRUN=${DT_DRYRUN}
  saved_ECHO=${DT_DRYRUN}
  dryrun_on
  DT_ECHO_STDOUT="y"
  DT_ECHO="n"
  $@ || return $?
  DT_ECHO_STDOUT="n"
  DT_DRYRUN=${saved_DRYRUN}
  DT_ECHO=${saved_ECHO}
}
