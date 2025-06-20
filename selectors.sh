select_exec() {
  local profile=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "profile" && \
  if [ "${profile}" = "docker" ]; then
    echo "docker_exec_cmd"
  elif [ "${profile}" = "docker_conn_sh" ]; then
    echo "docker_conn_sh"
  else
    echo "exec_cmd"
  fi
}

select_service_check() {
  local profile=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "profile" && \
  if [ "${profile}" = "docker" ]; then echo "docker_check"; else echo "service_check"; fi
}
