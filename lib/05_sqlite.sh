sqlite_init() {
  sqlite_paths && \
  sqlite_drop_db && \
  . ${DT_VARS}/vars.sh
}

sqlite_reset_id() {
  DT_ROWID=0
}

sqlite_next_id() {
  DT_ROWID=$((${DT_ROWID}+1));
  echo ${DT_ROWID}
}

sqlite_paths() {
  export DT_VARS_DB="${DT_VARS}/vars.db"
  export DT_SCHEMA="${DT_VARS}/schema.sql"
}

sqlite_conn() {
  sqlite3 "${DT_VARS_DB}" -cmd 'PRAGMA foreign_keys = ON;' -cmd '.headers ON' -cmd '.nullvalue <NULL>' -cmd '.mode column'
}

sqlite_migrate() {
  local err fname=$(fname "${FUNCNAME[0]}" "$0")
  exec_cmd "sqlite3 -batch "${DT_VARS_DB}" -cmd 'PRAGMA foreign_keys = ON;' < ${DT_SCHEMA}"
  err=$?
  if [ "${err}" != 0 ]; then
    dt_error ${fname} "${BOLD}exec_cmd${RESET} exited wit errcode=${BOLD}${err}${RESET}"; return 99
  fi
}

sqlite_exec() {
  local err fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -z "$1" ]; then dt_warning ${fname} "Argument query was not provided"; return 99; fi
  exec_cmd sqlite3 ""${DT_VARS_DB}" -cmd 'PRAGMA foreign_keys = ON;' <<EOF\n$1\nEOF"
  err=$?
  if [ "${err}" != 0 ]; then
    dt_error ${fname} "${BOLD}exec_cmd${RESET} exited wit errcode=${BOLD}${err}${RESET}"; return 99
  fi
}

sqlite_drop_db() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if [ -f "${DT_VARS_DB}" ]; then
    exec_cmd rm "${DT_VARS_DB}"
  else
    dt_warning ${fname} "Database '${BOLD}${DT_VARS_DB}${RESET}' doesn't exist"
  fi
}

get_row_args() {
  local wait fname=$(fname "${FUNCNAME[0]}" "$0")
  while [ "$#" -gt 0 ];
  do
    case $1 in
      -r|--record|--row)
        wait=$1
        shift
        ;;
      -t|--table)
        wait=$1
        shift
        ;;
      *)
        if [ -z "${wait}" ]; then dt_error ${fname} "Unexpected positional parameter: $1"; return 99; fi
        case ${wait} in
          -r|--record|--row)
            rowid=$1
            wait=
            shift
            ;;
          -t|--table)
            tbl=$1
            wait=
            shift
            ;;
          *)
            dt_error ${fname} "Invalid state of parser: wait=${wait}"; return 99;
            ;;
        esac
        ;;
    esac
  done
  dt_debug ${fname} "tbl=${tbl}; rowid=${rowid}"
  if [ -z "${tbl}" ]; then dt_error ${fname} "The option '-t|--table' is mandatory, but is was not provided"; return 99; fi
  if [ -z "${rowid}" ]; then dt_error ${fname} "The option '-r|--record|--row' is mandatory, but is was not provided"; return 99; fi
}

get_row() {
  local rowid tbl fname=$(fname "${FUNCNAME[0]}" "$0")
  get_row_args $@ && \
  read row < <(sqlite3 -batch -noheader "${DT_VARS_DB}" -cmd 'PRAGMA foreign_keys = ON;' "SELECT * FROM ${tbl} WHERE id=${rowid}")
  echo "${row}"
}
