function service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "brew services"
  else
    echo "systemctl"
  fi
}

service_modes() {
  local vars=(docker host)
  echo "${vars[@]}"
}

MODES=($(echo $(service_modes)))

select_service() {
  local prefix="$1" mode="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && err_if_empty ${fname} "prefix mode" && \
  echo "${prefix}_$(${mode})"
}

merge_os_service() {
  mvar MAJOR "0"
  mvar MINOR "0"
  mref SOCK "sockets" "pg"
  mref SOCK_PUB "sockets" $(echo "$(SOCK)" | cut -d':' -f 2)

  mvar SERVICE "unknown_os_service"
  mvar SERVICE_CHECK_CMD "psql_conn_admin -c $'select true;'"
  mvar SERVICE_PREPARE "pg_prepare"
  mvar SERVICE_INSTALL "pg_install"
  mvar SERVICE_POST_INSTALL "pg_post_install"
  mvar SERVICE_STOP $(service) stop $(SERVICE)
  mvar SERVICE_START $(service) start $(SERVICE)

  mvar CHECK "service_check"
  mvar EXEC "exec_cmd"
  mvar TERMINAL "exec_cmd"
}

service_check() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "$(SERVICE_CHECK_CMD)" ]; then dt_error ${fname} "Variable ${BOLD}SERVICE_CHECK${RESET} is empty"; return 99; fi
  for i in $(seq 1 30); do
    dt_info ${fname} "Waiting ${BOLD}$(SERVICE)${RESET} runtime: attempt ${BOLD}$i${RESET} ... ";
    if $(SERVICE_CHECK_CMD); then dt_info ${fname} "Service ${BOLD}$(SERVICE)${RESET} is up now"; return 0; fi
    sleep 1
  done
  return 99
}

_srv_ctx() { set_tbl "os_services" && set_rec "$1"; }

service_post_install() { _srv_ctx $1 && exec_cmd "$(SERVICE_POST_INSTALL)"; }
service_install() { _srv_ctx $1 && exec_cmd "$(SERVICE_INSTALL)"; }
service_prepare() { _srv_ctx $1 && exec_cmd "$(SERVICE_PREPARE)"; }
service_restart() { _srv_ctx $1 && exec_cmd "${SUDO} $(SERVICE_STOP)" && exec_cmd "${SUDO} $(SERVICE_START)"; }
service_start() { _srv_ctx $1 && exec_cmd "${SUDO} $(SERVICE_START)"; }
service_stop() { _srv_ctx $1 && exec_cmd "${SUDO} $(SERVICE_STOP)"; }

function methods_os_services() {
  local methods=()
  methods+=(service_check)
  methods+=(service_install)
  methods+=(service_prepare)
  methods+=(service_restart)
  methods+=(service_start)
  methods+=(service_stop)
  methods+=(service_post_install)
  echo "${methods[@]}"
}

# MacOS
function brew_list_services() { exec_cmd brew services list; }
function brew_start() { exec_cmd brew services start $1; }
function brew_stop() { exec_cmd brew services stop $1; }

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
