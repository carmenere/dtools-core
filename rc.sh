function self_dir() {
  #  $1: contains $0 of .sh script
  if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$1"; fi
  echo "$(dirname $(realpath "${self}"))"
}

dt_rc_load $(basename "$(self_dir "$0")") "$(self_dir "$0")"

. "$(self_dir "$0")/clickhouse/rc.sh"
. "$(self_dir "$0")/pg/rc.sh"
. "$(self_dir "$0")/redis/rc.sh"
. "$(self_dir "$0")/rabbitmq/rc.sh"
. "$(self_dir "$0")/rust/rc.sh"
. "$(self_dir "$0")/python/rc.sh"