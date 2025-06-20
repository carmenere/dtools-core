select_exec() {
  local profile=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "profile" && \
  if [ "${profile}" = "docker" ]; then echo "docker_exec_cmd"; else echo "exec_cmd"; fi
}

select_service_check() {
  local profile=$1 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "profile" && \
  if [ "${profile}" = "docker" ]; then echo "docker_check"; else echo "service_check"; fi
}
