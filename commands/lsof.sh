function lsofx() {
  local port host proto tbl="sockets" rec=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  port=$(PORT -t ${tbl} -r ${rec})
  host=$(HOST -t ${tbl} -r ${rec})
  proto=$(PROTO -t ${tbl} -r ${rec})
  dt_debug ${fname} "rec=${rec} tbl=${tbl} proto=${proto} host=${host} port=${port}"
  exec_cmd "$(dt_sudo) lsof -nP -i4${proto}@0.0.0.0:${port}"
  exec_cmd "$(dt_sudo) lsof -nP -i4${proto}@localhost:${port}"
  if [ "${host}" != "0.0.0.0" ] && [ "${host}" != "localhost" ]; then
    exec_cmd "$(dt_sudo) lsof -nP -i4${proto}@${host}:${port}"
  fi
}
