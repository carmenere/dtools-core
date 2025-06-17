function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

function service_stop() { cmd_exec "${SUDO} ${SERVICE_STOP}"; }
function service_start() { cmd_exec "${SUDO} ${SERVICE_START}"; }
function service_restart() { cmd_exec "${SUDO} ${SERVICE_STOP}" && cmd_exec "${SUDO} ${SERVICE_START}"; }
function service_prepare() { cmd_exec "${SERVICE_PREPARE}"; }
function service_install() { cmd_exec "${SERVICE_INSTALL}"; }
function service_lsof() { cmd_exec "${SERVICE_LSOF}"; }

function service_methods() {
  local methods=()
  methods+=(service_start)
  methods+=(service_stop)
  methods+=(service_restart)
  methods+=(service_prepare)
  methods+=(service_install)
  methods+=(service_lsof)
  echo "${methods[@]}"
}

ctx_os_service() {
  var SERVICE_STOP "$(service) stop ${SERVICE}"
  var SERVICE_START "$(service) start ${SERVICE}"
}

# MacOS
function brew_list_services() { cmd_exec brew services list; }
function brew_start() { cmd_exec brew services start $1; }
function brew_stop() { cmd_exec brew services stop $1; }

# Linux, systemd
function systemctl_list_services() { systemctl list-units --type service | cat; }
# lists all installed unit files
function systemctl_list_unit_files() { systemctl list-unit-files | cat; }
# lists units that systemd currently has in memory
function systemctl_list_units() { systemctl list-units | cat; }
# filter by type
function systemctl_list_units_automount() { systemctl list-units --type automount | cat; }
function systemctl_list_units_device() { systemctl list-units --type device | cat; }
function systemctl_list_units_mount() { systemctl list-units --type mount | cat; }
function systemctl_list_units_path() { systemctl list-units --type path | cat; }
function systemctl_list_units_scope() { systemctl list-units --type scope | cat; }
function systemctl_list_units_service() { systemctl list-units --type service | cat; }
function systemctl_list_units_slice() { systemctl list-units --type slice | cat; }
function systemctl_list_units_socket() { systemctl list-units --type socket | cat; }
function systemctl_list_units_swap() { systemctl list-units --type swap | cat; }
function systemctl_list_units_target() { systemctl list-units --type target | cat; }
function systemctl_list_units_timer() { systemctl list-units --type timer | cat; }

