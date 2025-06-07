function load() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"

  dt_rc_load $(basename "${self_dir}") "${self_dir}"
}

load $0

docker_vars=(${docker_image_vars[@]} ${docker_container_vars[@]} ${docker_network_vars[@]})

docker_methods=()
docker_methods+=(docker_build)
docker_methods+=(docker_service_check)
docker_methods+=(docker_exec)
docker_methods+=(docker_exec_sh)
docker_methods+=(docker_logs)
docker_methods+=(docker_pull)
docker_methods+=(docker_rm)
docker_methods+=(docker_rmi)
docker_methods+=(docker_run)
docker_methods+=(docker_start)
docker_methods+=(docker_status)
docker_methods+=(docker_stop)
docker_methods+=(docker_network_create)
docker_methods+=(docker_network_rm)
docker_methods+=(docker_network_ls)
