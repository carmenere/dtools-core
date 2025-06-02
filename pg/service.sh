function pg_dir() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/opt/postgresql@${MAJOR}/bin"
  elif [ "$(os_name)" = "alpine" ]; then
    echo "/usr/libexec/postgresql${MAJOR}"
  else
    echo "/usr/lib/postgresql/${MAJOR}/bin"
  fi
}

function pg_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "postgresql@${MAJOR}"
  else
    echo "postgresql"
  fi
}

function pg_hba_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/pg_hba.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/pg_hba.conf"
  fi
}

function pg_conf() {
  if [ "$(os_name)" = "macos" ]; then
    echo "$(brew_prefix)/var/$(pg_service)/postgresql.conf"
  else
    echo "/etc/postgresql/${MAJOR}/main/postgresql.conf"
  fi
}

# ctx_service_pg && pg_install
function pg_install() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      dt_exec "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list"; exit_on_err ${fname} $? || return $?
      dt_exec "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -"; exit_on_err ${fname} $? || return $?
      dt_exec "${SUDO} apt-get update"; exit_on_err ${fname} $? || return $?
      dt_exec "${SUDO} apt-get -y install \
          postgresql-${MAJOR} \
          postgresql-server-dev-${MAJOR} \
          libpq-dev"; exit_on_err ${fname} $? || return $?

  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec "brew install $(pg_service)"
  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function pg_add_path() {
  NPATH="${PATH}"
  echo "${NPATH}" | grep -E -s "^${PG_DIR}" 1>/dev/null 2>&1
  if [ $? != 0 ] && [ -n "${PG_DIR}" ]; then
    # Cut all duplicates of ${PG_DIR} from NPATH
    NPATH="$(echo "${NPATH}" | sed -E -e ":label; s|(.*):${PG_DIR}(.*)|\1\2|g; t label;")"
    # Prepend ${PG_DIR}
    echo "${PG_DIR}:${NPATH}"
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
  dt_exec "${SUDO} sed -i -E -e 's/^\s*#?\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' ${PG_HBA_CONF}"
}

function pg_conf_set_port() {
  dt_exec "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${PGPORT}/; t; \$a port = ${PGPORT}' ${PG_CONF}"
}

function pg_prepare() {
  local pg_hba_hash=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1)
  local pg_conf_hash=$(${SUDO} sha256sum "${PG_CONF}" | cut -d' ' -f 1)
  pg_hba_conf_add_policy
  pg_conf_set_port
  local pg_hba_hash_new=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1)
  local pg_conf_hash_new=$(${SUDO} sha256sum "${PG_CONF}" | cut -d' ' -f 1)
  if [ "${pg_hba_hash}" = "${pg_hba_hash_new}" ] && [ "${pg_conf_hash}" = "${pg_conf_hash_new}" ]; then return 0; fi
  service_stop
}

function ctx_pg_vars() {
  local fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  PG_DIR=$(pg_dir); exit_on_err ${fname} $? || return $?
  PG_HBA_CONF=$(pg_hba_conf); exit_on_err ${fname} $? || return $?
  PG_CONF=$(pg_conf); exit_on_err ${fname} $? || return $?
  # Depends on PG_DIR
  PG_CONFIG="${PG_DIR}/pg_config"
  PG_CONFIG_LIBDIR="$("${PG_CONFIG}" --pkglibdir | tr ' ' '\n')"
  PG_CONFIG_SHAREDIR="$("${PG_CONFIG}" --sharedir)"
  PG_BINDIR="$("${PG_CONFIG}" --bindir)"
  SERVICE_STOP="$(service) stop '$(pg_service)'"
  SERVICE_START="$(service) start '$(pg_service)'"
  SERVICE_PREPARE=pg_prepare
  SERVICE_INSTALL=pg_install
  SERVICE_LSOF=lsof_pg
}

function ctx_service_pg() {
  MAJOR=17
  MINOR=5
  PGHOST="localhost"
  PGPORT=5432
  ctx_pg_vars
}

function lsof_pg() {
  (
    PORT=${PGPORT}; HOST=${PGHOST}
    lsof_tcp
  )
}

dt_register "ctx_service_pg" "pg" "${service_methods[@]}"
