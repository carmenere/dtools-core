function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

function service_stop() {(
    dt_exec "${SUDO} ${SERVICE_STOP}"
)}

function service_start() {(
    dt_exec "${SUDO} ${SERVICE_START}"
)}

function service_restart() { service_stop && service_start; }
function service_prepare() { dt_exec "${SERVICE_PREPARE}"; }
function service_install() { dt_exec "${SERVICE_INSTALL}"; }
function service_lsof() { dt_exec "${SERVICE_LSOF}"; }

service_methods=()

service_methods+=(service_start)
service_methods+=(service_stop)
service_methods+=(service_restart)
service_methods+=(service_prepare)
service_methods+=(service_install)
service_methods+=(service_lsof)

# MacOS
function brew_list_services() { brew services list; }

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

