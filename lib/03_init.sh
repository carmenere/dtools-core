function dt_init() {
  local core_rc_dir
  core_rc_dir="$1"
  dt_paths "${core_rc_dir}" && \
  logging_init && \
  autocomplete_init && \
#  . "${DT_CORE}/clickhouse/rc.sh" && \
  . "${DT_CORE}/commands/rc.sh" && \
#  . "${DT_CORE}/redis/rc.sh" && \
#  . "${DT_CORE}/rabbitmq/rc.sh" && \
#  . "${DT_CORE}/cargo/rc.sh" && \
#  . "${DT_CORE}/python/rc.sh" && \
#  . "${DT_TOOLS}/rc.sh" && \
#  . "${DT_STANDS}/rc.sh" && \
#  if [ -f "${DT_LOCALS}/rc.sh" ]; then . "${DT_LOCALS}/rc.sh" || return $?; fi && \
#  . ${DTOOLS}/vars/vars.sh && \
  dt_autocomplete
}