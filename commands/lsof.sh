function lsof_tcp() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "${HOST_BIND}" != "0.0.0.0" ] && [ "${HOST_BIND}" != "localhost" ]; then
    exec_cmd "$(dt_sudo) lsof -nP -i4TCP@${HOST}:${PORT_BIND}"
  else
    exec_cmd "$(dt_sudo) lsof -nP -i4TCP@0.0.0.0:${PORT_BIND}"
    exec_cmd "$(dt_sudo) lsof -nP -i4TCP@localhost:${PORT_BIND}"
  fi
)}

function lsof_udp() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd "$(dt_sudo) lsof -nP -i4UDP@0.0.0.0:${PORT_BIND}"
  exec_cmd "$(dt_sudo) lsof -nP -i4UDP@localhost:${PORT_BIND}"
  if [ "${HOST_BIND}" != "0.0.0.0" ] && [ "${HOST_BIND}" != "localhost" ]; then
      exec_cmd "$(dt_sudo) lsof -nP -i4UDP@${HOST_BIND}:${PORT_BIND}"
  fi
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_lsof() {
  local methods=()
  methods+=(lsof_tcp)
  methods+=(lsof_udp)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_lsof"