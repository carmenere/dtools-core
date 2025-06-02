function lsof_tcp() {
  dt_exec "sudo lsof -nP -i4TCP@0.0.0.0:${PORT}"
  dt_exec "sudo lsof -nP -i4TCP@localhost:${PORT}"
  if [ "${HOST}" != "0.0.0.0" ] && [ "${HOST}" != "localhost" ]; then
      dt_exec "sudo lsof -nP -i4TCP@${HOST}:${PORT}"
  fi
}

function lsof_udp() {
  dt_exec "sudo lsof -nP -i4UDP@0.0.0.0:${PORT}"
  dt_exec "sudo lsof -nP -i4UDP@localhost:${PORT}"
  if [ "${HOST}" != "0.0.0.0" ] && [ "${HOST}" != "localhost" ]; then
      dt_exec "sudo lsof -nP -i4UDP@${HOST}:${PORT}"
  fi
}