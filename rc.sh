function dt_rc_load() {
  description=$1
  dir=$2
  if [ -z "${description}" ]; then return 99; fi
  if [ -z "${dir}" ]; then return 99; fi
  echo -e "Loading ${BOLD}$description${RESET} ... "
  for file in "$dir"/*.sh; do
    if [ "$(basename "$file")" != "rc.sh"  ]; then
      echo -e -n "Sourcing "$(dirname "$file")/${BOLD}$(basename "$file")${RESET}" ..."
      . "$file" || return 55
      echo "done.";
    fi
  done
}

function dt_init() {
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi
  local self_dir="$(dirname $(realpath "${self}"))"
  . "${self_dir}/colors.sh" && \
  . "${self_dir}/lib.sh" && \
  drop_all_ctxes && \
  dt_paths && \
  dt_defaults && \
  dt_rc_load $(basename "${self_dir}") "${self_dir}" && \
  . "${self_dir}/clickhouse/rc.sh" && \
  . "${self_dir}/pg/rc.sh" && \
  . "${self_dir}/redis/rc.sh" && \
  . "${self_dir}/rabbitmq/rc.sh" && \
  . "${self_dir}/cargo/rc.sh" && \
  . "${self_dir}/python/rc.sh" && \
  . "${DT_TOOLS}/rc.sh" && \
  . "${DT_STANDS}/rc.sh" && \
  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi
  dt_register
#  init_deps
}

dt_init $0