function pg_dir() {
  if [ "$(os_name)" = "macos" ]; then
    BIN_DIR="$(brew_prefix)/opt/postgresql@${MAJOR}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    BIN_DIR="/usr/libexec/postgresql${MAJOR}"
  else
    BIN_DIR="/usr/lib/postgresql/${MAJOR}/bin"
  fi
}

function pg_hba_conf() {
  if [ "$(os_name)" = "macos" ]; then
    PG_HBA_CONF="$(brew_prefix)/var/${SERVICE}/pg_hba.conf"
  else
    PG_HBA_CONF="/etc/postgresql/${MAJOR}/main/pg_hba.conf"
  fi
}

function pg_conf() {
  if [ "$(os_name)" = "macos" ]; then
    POSTGRESQL_CONF="$(brew_prefix)/var/${SERVICE}/postgresql.conf"
  else
    POSTGRESQL_CONF="/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

function pg_paths() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  pg_dir && pg_hba_conf && pg_conf || return $?
  # Depends on BIN_DIR
  PG_CONFIG="${BIN_DIR}/pg_config"
  PSQL="${BIN_DIR}/psql"
  if [ ! -x "${PG_CONFIG}" ]; then
    dt_warning ${fname} "The binary '${PG_CONFIG}' doesn't exist. Maybe pg of version ${MAJOR} hasn't been installed yet?"
  else
    CONFIG_LIBDIR="$("${PG_CONFIG}" --pkglibdir | tr ' ' '\n')"
    CONFIG_SHAREDIR="$("${PG_CONFIG}" --sharedir)"
  fi
}

function pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    SERVICE="postgresql@${MAJOR}"
  else
    SERVICE="postgresql"
  fi
  pg_paths || return $?
  STOP_CMD="$(service) stop '${SERVICE}'"
  START_CMD="$(service) start '${SERVICE}'"
  PREPARE_CMD=pg_prepare
  INSTALL_CMD=pg_install
  LSOF=lsof_pg
}

# ctx_service_pg && pg_install
function pg_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
    dt_exec ${fname} "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list" || return $?
    dt_exec ${fname} "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -" || return $?
    dt_exec ${fname} "${SUDO} apt-get update" || return $?
    dt_exec ${fname} "${SUDO} apt-get -y install \
      postgresql-${MAJOR} \
      postgresql-server-dev-${MAJOR} \
      libpq-dev" || return $?
  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec ${fname} "brew install ${SERVICE}"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function pg_add_path() {
  NPATH="${PATH}"
  echo "${NPATH}" | grep -E -s "^${BIN_DIR}" 1>/dev/null 2>&1
  if [ $? != 0 ] && [ -n "${BIN_DIR}" ]; then
    # Cut all duplicates of ${BIN_DIR} from NPATH
    NPATH="$(echo "${NPATH}" | sed -E -e ":label; s|(.*):${BIN_DIR}(.*)|\1\2|g; t label;")"
    # Prepend ${BIN_DIR}
    echo "${BIN_DIR}:${NPATH}"
  else
    echo "${NPATH}"
  fi
}

# sed branching - Example
#echo "apple pie
#apple tart
#banana split" | sed '/apple/ { s/apple/peach/; t; s/pie/cobbler/; }'
#Output:
#peach cobbler
#peach tart
#banana split

#First, we target lines containing “apple” with the /apple/ address.
#Inside the curly braces {}, we make a series of commands to execute.
#The s/apple/peach/ command replaces “apple” with “peach”.
#The t command checks if the above substitution was successful. If it was, it branches to the end of the commands inside the curly braces, skipping the next command. If no substitution was done, it continues executing the subsequent commands.
#The s/pie/cobbler/ command is only executed if the previous s/apple/peach/ substitution wasn’t done.

#Check pattern
#1) If host all all 0.0.0.0\/0 md5 presents in file - do nothing.
#2) If not: check commented or not
#2.1) if commented - cut "host all all 0.0.0.0\/0 md5" and replace
#2.2) if not just append "host all all 0.0.0.0\/0 md5" to the end
#
# sed doc:
# 1) Consider example sed -n -e '1i Header' -e '$a Trailer' <FILE>
#   '1i Header'  : here pattern "1" matches 1st line and command "i" inserts 'Header' before it
#   '$a Trailor' : here pattern "$" matches last line and command "a" appends 'Trailor' after it
# 2) The "t;" command checks if the previous substitution was successful. If it was, it goto  to the end of the block , skipping the next commands.
function pg_hba_conf_add_policy() {
  local fname old_hash new_hash
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PG_HBA_CONF" || return $?
  old_hash=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1) || return $?
  dt_exec ${fname} "${SUDO} sed -i -E -e 's/^\s*#?\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' ${PG_HBA_CONF}" || return $?
  new_hash=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1) || return $?
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "${PG_HBA_CONF} is ${BOLD}is changed${RESET}"; return 59
  else
    dt_info ${fname} "${PG_HBA_CONF} is ${BOLD}not changed${RESET}"
  fi
}

function pg_conf_set_port() {
  local fname old_hash new_hash
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  dt_err_if_empty ${fname} "PGPORT" || return $?
  dt_err_if_empty ${fname} "POSTGRESQL_CONF" || return $?
  old_hash=$(${SUDO} sha256sum "${POSTGRESQL_CONF}" | cut -d' ' -f 1) || return $?
  dt_exec ${fname} "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${PGPORT}/; t; \$a port = ${PGPORT}' ${POSTGRESQL_CONF}" || return $?
  new_hash=$(${SUDO} sha256sum "${POSTGRESQL_CONF}" | cut -d' ' -f 1) || return $?
  if [ "${old_hash}" != "${new_hash}" ]; then
    dt_info ${fname} "${POSTGRESQL_CONF} is ${BOLD}is changed${RESET}"; return 59
  else
    dt_info ${fname} "${POSTGRESQL_CONF} is ${BOLD}not changed${RESET}"
  fi
}

function pg_prepare() {
  local changed
  pg_hba_conf_add_policy; if [ "$?" = 59 ]; then changed="y"; fi
  pg_conf_set_port; if [ "$?" = 59 ]; then changed="y"; fi
  if [ "${changed}" != "y" ]; then return 0; fi
  service_stop
}

function lsof_pg() {
  PORT=${PGPORT}; HOST=${PGHOST}
  lsof_tcp
}

function ctx_service_pg() {
  MAJOR=17
  MINOR=5
  PGHOST="localhost"
  PGPORT=5430
  pg_service
}

dt_register "ctx_service_pg" "pg" "${service_methods[@]}"
