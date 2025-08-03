function dt_init() {
  local self_dir self
  if [ -n "${BASH_SOURCE}" ]; then local self="${BASH_SOURCE[0]}"; else local self="$1"; fi && \
  self_dir="$(dirname $(realpath "${self}"))" && \
  dt_paths && \
  logging_init && \
  autocomplete_init && \
  dt_rc_load $(basename "${self_dir}") "${self_dir}" && \
#  . "${self_dir}/clickhouse/rc.sh" && \
  . "${self_dir}/commands/rc.sh" && \
#  . "${self_dir}/redis/rc.sh" && \
#  . "${self_dir}/rabbitmq/rc.sh" && \
#  . "${self_dir}/cargo/rc.sh" && \
#  . "${self_dir}/python/rc.sh" && \
#  . "${DT_TOOLS}/rc.sh" && \
#  . "${DT_STANDS}/rc.sh" && \
#  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi && \
#  . ${DTOOLS}/vars/vars.sh && \
  dt_autocomplete_all
}