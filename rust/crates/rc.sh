function self_dir() {
  if [ -n "${BASH_SOURCE}" ]; then self="${BASH_SOURCE[0]}"; else self="$1"; fi
  echo "$(dirname $(realpath "${self}"))"
}

dt_rc_load $(basename "$(self_dir "$0")") "$(self_dir "$0")"
