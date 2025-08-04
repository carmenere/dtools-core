_psql_sudo() {
  if [ "$(pg_mode)" = "docker" ]; then
    echo ""
    return 0
  fi
  if [ -n "$(dt_sudo)" ]; then
    echo "$(dt_sudo) -u $(PGUSER)"
  else
    echo ""
  fi
}

psql_conn() { ( set -eu; . "${DT_VARS}/connurls/pg/$1.sh" && _psql_conn ) }
_psql_conn() { . "${ACCOUNT}" && ${TERMINAL} $(_pg_connurl) ${PSQL}; }


_psql_host() { if [ -n "${host}" ]; then echo "PGHOST=${host}"; fi; }
_psql_port() { if [ -n "${port}" ]; then echo "PGPORT=${port}"; fi; }
_psql_user() { if [ -n "${user}" ]; then echo "PGUSER=${user}"; fi; }
_psql_password() { if [ -n "${password}" ]; then echo "PGPASSWORD=${password}"; fi }
_psql_db() { if [ -n "${database}" ]; then echo "PGDATABASE=${database}"; fi }
_pg_connurl() { echo "$(_psql_host) $(_psql_port) $(_psql_db) $(_psql_user) $(_psql_password)" }

#_psql_rec() { set_tbl "psql_queries" && set_rec "$1"; }

#_pg_local_connurl() { echo "$(_psql_port) $(_psql_db $1) $(_psql_user) $@"; }
#_psql_conn() { local db=$1; echo "$(_pg_connurl ${db}) $(CLIENT $(SERVICE $(CONN))) $@"; }
#_psql_local_conn() { local db=$1; echo "$(_psql_sudo) $(_pg_local_connurl ${db}) $(CLIENT $(SERVICE $(CONN))) $@"; }
#
#_psql_gexec() {
#  local q db=$2 _conn=${_conn}
#  q=$(escape_quote $1) && \
#  if [ -z "${_conn}" ]; then _conn=_psql_conn; fi
#  $(EXEC $(SERVICE $(CONN))) "echo $'${q}' '\gexec' | $(${_conn})"
#}
#_psql_gexec_local() { local _conn=_psql_local_conn; _psql_gexec $@; }
#
#psql_local_conn() { local connurl=ACCOUNT; _psql_rec $1 && $(TERMINAL $(SERVICE $(CONN))) "$(_psql_local_conn)"; }
#psql_conn() { local connurl=ACCOUNT; _psql_rec $1 && $(TERMINAL $(SERVICE $(CONN))) "$(_psql_conn)"; }
#
#psql_alter_role_password() { local connurl=CONN && _psql_rec $1 && _psql_gexec_local "$(ALTER_PASSWORD)" }
#psql_drop_role_password() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(DROP_PASSWORD)" }
#psql_create_user() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(CREATE)" }
#psql_drop_user() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(DROP)" }
#psql_create_db() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(CREATE_DB)" }
#psql_drop_db() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(DROP_DB)" }
#psql_grant_user() { local connurl=CONN && _psql_rec $1 && _psql_gexec "$(GRANT)" "$(DATABASE $(ACCOUNT))"; }
#psql_revoke_user() {}
#
#methods_conns() {
#  local methods=()
#  methods+=(psql_alter_role_password)
#  methods+=(psql_conn)
#  methods+=(psql_local_conn)
#  methods+=(psql_create_db)
#  methods+=(psql_create_user)
#  methods+=(psql_drop_db)
#  methods+=(psql_drop_role_password)
#  methods+=(psql_drop_user)
#  methods+=(psql_grant_user)
#  methods+=(psql_revoke_user)
#  echo "${methods[@]}"
#}
#
#_psql_init() {
#  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
#  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
#  err_if_empty ${fname} "admin migrator app" && \
#  psql_create_db ${migrator} && \
#  psql_create_user ${migrator} && \
#  psql_grant_user ${migrator} && \
#  psql_create_user ${app} && \
#  psql_grant_user ${app}
#}
#
#_psql_clean() {
#  local admin="$1" migrator="$2" app="$3" fname=$(fname "${FUNCNAME[0]}" "$0")
#  dt_debug ${fname} "admin=${admin}, migrator=${migrator}, app=${app}" && \
#  err_if_empty ${fname} "admin migrator app" && \
#  psql_drop_db ${migrator} && \
#  psql_drop_user ${migrator} && \
#  psql_drop_user ${app}
#}
#
#function psql_init() { _psql_init admin migrator app; }
#function psql_clean() { _psql_clean admin migrator app; }

##################################################### AUTOCOMPLETE #####################################################
function methods_psql() {
  local methods=()
  methods+=(psql_conn)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_psql)
DT_AUTOCOMPLETIONS["methods_psql"]=""