function lsof_tcp() {
  exec_cmd "$(dt_sudo) lsof -nP -i4TCP@0.0.0.0:${PORT}"
  exec_cmd "$(dt_sudo) lsof -nP -i4TCP@localhost:${PORT}"
  if [ "${HOST}" != "0.0.0.0" ] && [ "${HOST}" != "localhost" ]; then
      exec_cmd "$(dt_sudo) lsof -nP -i4TCP@${HOST}:${PORT}"
  fi
}

function lsof_udp() {
  exec_cmd "$(dt_sudo) lsof -nP -i4UDP@0.0.0.0:${PORT}"
  exec_cmd "$(dt_sudo) lsof -nP -i4UDP@localhost:${PORT}"
  if [ "${HOST}" != "0.0.0.0" ] && [ "${HOST}" != "localhost" ]; then
      exec_cmd "$(dt_sudo) lsof -nP -i4UDP@${HOST}:${PORT}"
  fi
}