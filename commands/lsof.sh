_lsof() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "${HOST_BIND}" != "0.0.0.0" ] && [ "${HOST_BIND}" != "localhost" ]; then
    exec_cmd "$(dt_sudo) lsof -nP -i4$2@${HOST_BIND}:${PORT_BIND}"
  else
    exec_cmd "$(dt_sudo) lsof -nP -i4$2@0.0.0.0:${PORT_BIND}" || true
    exec_cmd "$(dt_sudo) lsof -nP -i4$2@localhost:${PORT_BIND}"
  fi
)}

lsof_tcp() { _lsof $1 TCP; }
lsof_udp() { _lsof $1 UDP; }

##################################################### AUTOCOMPLETE #####################################################
cmd_family_lsof() {
  local methods=()
  methods+=(lsof_tcp)
  methods+=(lsof_udp)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_lsof"