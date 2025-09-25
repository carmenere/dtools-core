pigzX() {(
  exec_cmd cd "${DT_LOGS}"
  local TGZ="$1"
  dt_mkdir "$(dirname "${TGZ}")"
  exec_cmd tar --use-compress-program=pigz -cv -f "${TGZ}" .
)}