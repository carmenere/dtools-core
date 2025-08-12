_service_cmd() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  docker=$2 brew=$3 systemctl=$4
  if [ "${MODE}" = "docker" ]; then
    exec_cmd ${docker} "$1"
  elif [ "${MODE}" = "host" ]; then
    if [ "$(os_name)" = "macos" ]; then
      exec_cmd ${brew} "$1"
    elif [ "$(os_name)" = "ubuntu" ]; then
      exec_cmd ${systemct} "$1"
    else
      dt_error "${fname}" "Unsupported os_name '$(os_name)'"
    fi
  else
    dt_error "${fname}" "Unsupported mode '${MODE}'"
  fi
)}

service_start() { _service_cmd "$1" "docker_run" "brew_start" "systemctl_start"; }
service_stop() { _service_cmd "$1" "docker_stop" "brew_stop" "systemctl_stop"; }
service_restart() { service_stop $1 && service_start $1; }
service_show() { _service_cmd "$1" "docker_ps" "brew_show" "systemctl_show"; }
service_show_all() { _service_cmd "$1" "docker_ps_all" "brew_show_all" "systemctl_show_all"; }

##################################################### AUTOCOMPLETE #####################################################
cmd_family_service() {
  local methods=()
  methods+=(service_start)
  methods+=(service_stop)
  methods+=(service_restart)
  methods+=(service_show)
  methods+=(service_show_all)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_service"
