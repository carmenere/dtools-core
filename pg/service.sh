version=( MAJOR MINOR PATCH )
pg_socket=( PGHOST PGPORT )
pg_paths=( BIN_DIR PG_HBA_CONF POSTGRESQL_CONF PG_CONFIG CONFIG_LIBDIR CONFIG_SHAREDIR )
pg_vars=( ${version[@]} ${pg_socket[@]} ${pg_paths[@]} ${service[@]} )

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
  pg_dir && pg_hba_conf && pg_conf; err=$?
  if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi

  # Depends on BIN_DIR
  PG_CONFIG="${BIN_DIR}/pg_config"
  if [ ! -x "${BIN_DIR}" ]; then
    dt_warning "The binary '${PG_CONFIG}' doesn't exist. Maybe pg of version ${MAJOR} hasn't been installed yet?"
  else
    CONFIG_LIBDIR="$("${PG_CONFIG}" --pkglibdir | tr ' ' '\n')"
    CONFIG_SHAREDIR="$("${PG_CONFIG}" --sharedir)"
  fi
}

function pg_service() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi

  if [ "$(os_name)" = "macos" ]; then
    SERVICE="postgresql@${MAJOR}"
  else
    SERVICE="postgresql"
  fi

  pg_paths; err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi

  STOP="$(service) stop '${SERVICE}'"
  START="$(service) start '${SERVICE}'"
  PREPARE=pg_prepare
  INSTALL=pg_install
  LSOF=lsof_pg
}

# ctx_service_pg && pg_install
function pg_install() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      dt_exec "echo 'deb http://apt.postgresql.org/pub/repos/apt $(os_codename)-pgdg main' | ${SUDO} tee /etc/apt/sources.list.d/pgdg.list"
      err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi
      dt_exec "${SUDO} wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | ${SUDO} apt-key add -"
      err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi
      dt_exec "${SUDO} apt-get update"
      err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi
      dt_exec "${SUDO} apt-get -y install \
          postgresql-${MAJOR} \
          postgresql-server-dev-${MAJOR} \
          libpq-dev"
          err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi

  elif [ "$(os_kernel)" = "Darwin" ]; then
    dt_exec "brew install ${SERVICE}"
  else
    echo "Unsupported OS: '$(os_kernel)'"; return 99
  fi
}

function pg_add_path() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
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
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
  old_hash=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1)
  dt_exec "${SUDO} sed -i -E -e 's/^\s*#?\s*host\s+all\s+all\s+0.0.0.0\/0\s+md5\s*$/host all all 0.0.0.0\/0 md5/; t; \$a host all all 0.0.0.0\/0 md5' ${PG_HBA_CONF}"
  err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi
  new_hash=$(${SUDO} sha256sum "${PG_HBA_CONF}" | cut -d' ' -f 1)
  if [ "${old_hash}" != "${new_hash}" ]; then echo "changed"; fi
}

function pg_conf_set_port() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
  local old_hash=$(${SUDO} sha256sum "${POSTGRESQL_CONF}" | cut -d' ' -f 1)
  dt_exec "${SUDO} sed -i -E -e 's/^\s*#?\s*(port\s*=\s*[0-9]+)\s*$/port = ${PGPORT}/; t; \$a port = ${PGPORT}' ${POSTGRESQL_CONF}"
  err=$?; if [ "${err}" != 0 ]; then dt_error $0 "err=${err}"; return ${err}; fi
  local new_hash=$(${SUDO} sha256sum "${POSTGRESQL_CONF}" | cut -d' ' -f 1)
  if [ "${old_hash}" != "${new_hash}" ]; then echo "changed"; fi
}

function pg_prepare() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
  changed1=$(pg_hba_conf_add_policy) || return $?
  changed2=$(pg_conf_set_port) || return $?
  if [ -z "${changed1}" ] && [ -z "${changed2}" ]; then return 0; fi
  service_stop
}

function lsof_pg() {
  if [ -n "$1" ]; then
    ctx=$1; for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
    dt_load_ctx ${ctx} ${pg_vars[@]}
  fi
  PORT=${PGPORT}; HOST=${PGHOST}
  lsof_tcp
}

function pg_v17() {
  for var in ${pg_vars[@]}; do local ${var} 1>/dev/null 2>1; done
  local ctx=$0
  MAJOR=17
  MINOR=5
  PGHOST="localhost"
  PGPORT=5432
  pg_service
  dt_set_ctx $ctx ${pg_vars[@]}
}

dt_register "pg_v17" "pg" "${service_methods[@]}"
