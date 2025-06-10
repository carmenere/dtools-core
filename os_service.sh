function os_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

#
function service_stop() {
  local ctx fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  "${stop_cmd}"
}

function service_start() {
  local fname ctx start_cmd; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  start_cmd=$(gvar ${ctx} START_CMD)
  ${start_cmd}
}

function service_restart() { service_stop && service_start; }

function service_prepare() {
  local fname ctx prepare_cmd; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  start_cmd=$(gvar ${ctx} START_CMD)
  ${prepare_cmd}
}

function service_install() {
  local fname ctx install_cmd; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  start_cmd=$(gvar ${ctx} START_CMD)
  ${install_cmd}
}

function service_lsof() {
  local fname ctx lsof_cmd; fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  start_cmd=$(gvar ${ctx} START_CMD)
  ${lsof_cmd}
}

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

