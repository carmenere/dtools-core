function install_postgres() {(
  local fname=install_postgres
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

post_install_postgres() {(
  local fname=post_install_postgres
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    if ! pg_lsclusters | cut -d' ' -f 1 | grep -m 1 "${MAJOR}"; then
      exec_cmd ${SUDO} pg_createcluster ${MAJOR} main
      exec_cmd ${SUDO} pg_ctlcluster ${MAJOR} main start
    fi
  fi
)}

# For example, vars/conns/pg_17/admin.sh contains both ${port_app} and ${port_client}, but ${port_client} is for psql_XXX commands
# The ${port_app} is for application
pg_conn_url() { echo "postgres://${user}:${password}@${host}:${port_app}/${database}"; }

pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${MAJOR}"
  else
    echo "postgresql@${MAJOR}-main.service"
  fi
}

pg_data_directory() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/${OS_SERVICE}"
  else
    echo "/var/lib/postgresql/${MAJOR}/main"
  fi
}

pg_postgresql.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/postgresql.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

pg_pg_hba.conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/pg_hba.conf"
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

pg_prepare() {(
  set -eu
  local FILE hash_old hash_new fname=pg_prepare
  local changed=0
  . "${DT_VARS}/services/$1.sh"
  if [ "${MODE}" != "host" ]; then
    dt_warning ${fname} "Service ${BOLD}$1${RESET}: MODE != host, skip prepare"
    return 0
  fi

  FILE=$(pg_pg_hba.conf)
  hash_old=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  m4_pg_hba.conf $1 || return $?
  hash_new=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  if [ "${hash_old}" != "${hash_new}" ]; then
    changed=1
    dt_warning ${fname} "File ${FILE} was ${BOLD}changed${RESET}, service will be stopped"
  fi

  FILE=$(pg_postgresql.conf)
  hash_old=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  m4_postgresql.conf $1 || return $?
  hash_new=$(${SUDO} sha256sum "${FILE}" | cut -d' ' -f 1)
  if [ "${hash_old}" != "${hash_new}" ]; then
    changed=1
    dt_warning ${fname} "File ${FILE} was ${BOLD}changed${RESET}, service will be stopped"
  fi

  if [ "${changed}" != 0 ]; then service_stop $1; fi
)}

m4_postgresql.conf() {( set -eu; . "${DT_VARS}/m4/$1/postgresql.conf.sh" && _m4 )}
m4_pg_hba.conf() {( set -eu; . "${DT_VARS}/m4/$1/pg_hba.conf.sh" && _m4 )}


##################################################### AUTOCOMPLETE #####################################################
function cmd_family_pg_services() {
  local methods=()
  methods+=(install_postgres)
  methods+=(install_postgis)
  methods+=(post_install_postgres)
  methods+=(m4_postgresql.conf)
  methods+=(m4_pg_hba.conf)
  methods+=(postgis_install)
  methods+=(pg_prepare)
  methods+=(pg_check)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_pg_services"