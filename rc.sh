function load() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"

  dt_rc_load $(basename "${self_dir}") "${self_dir}"
  
  . "${self_dir}/clickhouse/rc.sh"
  . "${self_dir}/pg/rc.sh"
  . "${self_dir}/redis/rc.sh"
  . "${self_dir}/rabbitmq/rc.sh"
  . "${self_dir}/rust/rc.sh"
  . "${self_dir}/python/rc.sh"
}

load $0
