function pg_install() {(
  local fname=pg_install
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    exec_cmd "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list"
    exec_cmd "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -"
    exec_cmd "${SUDO} apt-get update"
    exec_cmd "${SUDO} apt-get -y install \
      postgresql-${MAJOR} \
      postgresql-server-dev-${MAJOR} \
      libpq-dev" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install ${OS_SERVICE}"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
)}

pg_post_install() {(
  local fname=pg_post_install
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    if ! pg_lsclusters | cut -d' ' -f 1 | grep -m 1 "${MAJOR}"; then
      exec_cmd ${SUDO} pg_createcluster ${MAJOR} main
      exec_cmd ${SUDO} pg_ctlcluster ${MAJOR} main start
    fi
  fi
)}

# For example, vars/conns/pg/admin.sh contains both ${port_app} and ${port_client}, but ${port_client} is for psql_XXX commands
# The ${port_app} is for application
pg_conn_url() { echo "postgres://${user}:${password}@${host}:${port_app}/${database}"; }

pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${MAJOR}"
  else
    echo "postgresql@${MAJOR}-main.service"
  fi
}

pg_postgresql.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${OS_SERVICE}/postgresql.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

pg_pg_hba.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${OS_SERVICE}/pg_hba.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/pg_hba.conf"
  fi
}

pg_superuser() {
  if [ "$(os_name)" = "macos" ]; then
    echo "${USER}"
  else
    echo "postgres"
  fi
}

pg_bin_dir() {
  local fname=bin_dir
  if [ "$(os_name)" = "macos" ]; then
    bind_dir="$(brew_prefix)/opt/postgresql@${MAJOR}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    bind_dir="/usr/libexec/postgresql${MAJOR}"
  else
    bind_dir="/usr/lib/postgresql/${MAJOR}/bin"
  fi
  if [ ! -d "${bind_dir}" ]; then
    dt_warning ${fname} "The directory '${bind_dir}' doesn't exist"
  fi
  echo "${bind_dir}"
}

#pg_add_path() {
#  local fname=pg_add_path
#  path="${PATH}"
#  echo "${path}" | grep -E -s "^${BIN_DIR}" 1>/dev/null 2>&1
#  if [ $? != 0 ] && [ -n "${BIN_DIR}" ]; then
#    # Cut all duplicates of ${BIN_DIR} from path
#    path="$(echo "${path}" | sed -E -e ":label; s|(.*):${BIN_DIR}(.*)|\1\2|g; t label;")"
#    # Prepend ${BIN_DIR}
#    dt_debug ${fname} "${BIN_DIR}:${path}"
#  else
#    dt_debug ${fname} "${path}"
#  fi
#}

m4_postgresql.conf() {( set -eu; . "${DT_VARS}/m4/$1/postgresql.conf.sh" && _m4 )}
m4_pg_hba.conf() {( set -eu; . "${DT_VARS}/m4/$1/pg_hba.conf.sh" && _m4 )}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_m4_pg() {
  local methods=()

  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_m4_pg"

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_pg_services() {
  local methods=()
  methods+=(pg_install)
  methods+=($(cmd_family_pg_ctl))
  methods+=(m4_postgresql.conf)
  methods+=(m4_pg_hba.conf)
  methods+=(postgis_install)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_pg_services"