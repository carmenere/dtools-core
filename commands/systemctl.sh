systemctl_start() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd systemctl start "${SERVICE}"
)}

systemctl_stop() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd systemctl stop "${SERVICE}"
)}

systemctl_restart() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd systemctl restart "${SERVICE}"
)}

systemctl_show() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd systemctl status "${SERVICE}"
)}

systemctl_show_all() { systemctl list-units --type service --all | cat; }

################################################### Additional commands ##################################################
## Linux, systemd
#function systemctl_list_services() { systemctl list-units --type service | cat; }
## lists all installed unit files
#function systemctl_list_unit_files() { systemctl list-unit-files | cat; }
## lists units that systemd currently has in memory
#function systemctl_list_units() { systemctl list-units | cat; }
## filter by type
#function systemctl_list_units_automount() { systemctl list-units --type automount | cat; }
#function systemctl_list_units_device() { systemctl list-units --type device | cat; }
#function systemctl_list_units_mount() { systemctl list-units --type mount | cat; }
#function systemctl_list_units_path() { systemctl list-units --type path | cat; }
#function systemctl_list_units_scope() { systemctl list-units --type scope | cat; }
#function systemctl_list_units_service() { systemctl list-units --type service | cat; }
#function systemctl_list_units_slice() { systemctl list-units --type slice | cat; }
#function systemctl_list_units_socket() { systemctl list-units --type socket | cat; }
#function systemctl_list_units_swap() { systemctl list-units --type swap | cat; }
#function systemctl_list_units_target() { systemctl list-units --type target | cat; }
#function systemctl_list_units_timer() { systemctl list-units --type timer | cat; }

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_systemctl() {
  local methods=()
  methods+=(systemctl_start)
  methods+=(systemctl_stop)
  methods+=(systemctl_restart)
  methods+=(systemctl_show)
  methods+=(systemctl_show_all)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_rustup"
