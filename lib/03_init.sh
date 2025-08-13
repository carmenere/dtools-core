function dt_init() {
  local core_rc_dir
  core_rc_dir="$1"
  dt_paths "${core_rc_dir}" && \
  logging_init && \
  autocomplete_init && \
  . "${DT_CORE}/commands/rc.sh" && \
#  . "${DT_STANDS}/rc.sh" && \
  dt_autocomplete
}
