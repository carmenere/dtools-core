function pg_connurl() {
  local vars=(PGDATABASE)
  vars+=(PGHOST)
  vars+=(PGPASSWORD)
  vars+=(PGPORT)
  vars+=(PGUSER)
  echo "${vars}"
}

function psql_conn() {
  local fname ctx cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  ctx=$1; dt_err_if_empty ${fname} "ctx" || return $?
  p=$(mpref ${ctx})
  local PGDATABASE=$(${p}database)
  local PGHOST=$(${p}host)
  local PGPASSWORD=$(${p}password)
  local PGPORT=$(${p}port)
  local PGUSER=$(${p}user)
  local PSQL=$(${p}psql)
  dt_err_if_empty ${fname} "PSQL" || return $?
  cmd=($(dt_inline_envs "$(pg_connurl)"))
  cmd+=("${PSQL}")
  dt_exec ${fname} "${cmd[@]}"
}

function psql_exec() {
  local fname query_ctx conn_ctx query conn cmd
  fname=$(dt_fname "${FUNCNAME[0]}" "$0")
  query_ctx=$1; dt_err_if_empty ${fname} "query_ctx" || return $?
  conn_ctx=$2; dt_err_if_empty ${fname} "conn_ctx" || return $?
  query=$3; dt_err_if_empty ${fname} "query" || return $?
  query=$(${query} ${query_ctx}) || return $?
  conn=$(dt_echo psql_conn ${conn_ctx}) || return $?
  cmd="echo $'${query}' '\gexec' | ${conn}"
  dt_exec ${fname} "${cmd}"
}

function psql_alter_role_password() { psql_exec $1 $2 pg_sql_alter_role_password; }
function psql_create_db() { psql_exec $1 $2 pg_sql_create_db; }
function psql_create_user() { psql_exec $1 $2 pg_sql_create_user; }
function psql_drop_db() { psql_exec $1 $2 pg_sql_drop_db; }
function psql_drop_user() { psql_exec $1 $2 pg_sql_drop_user; }
function psql_grant_user_app() { psql_exec $1 $2 pg_sql_grant_user_app; }
function psql_grant_user_migrator() { psql_exec $1 $2 pg_sql_grant_user_migrator; }
function psql_revoke_user_app() { psql_exec $1 $2 pg_sql_revoke_user_app; }
function psql_revoke_user_migrator() { psql_exec $1 $2 pg_sql_revoke_user_migrator; }

function _psql_init() {
  local admin migrator app
  admin=$1
  migrator=$2
  app=$3
  psql_alter_role_password $admin $admin && \
  psql_create_db $migrator $admin && \
  psql_create_user $migrator $admin && \
  psql_grant_user_migrator $migrator $admin && \
  psql_create_user $app $admin && \
  # Connect to db behalf 'migrator'!
  psql_grant_user_app $app $migrator
}

function _psql_clean() {
  local admin migrator app
  admin=$1
  migrator=$2
  app=$3
  $admin && $migrator && $app
#  psql_revoke_user_app $app $admin && \
#  psql_revoke_user_migrator $migrator $admin && \
#  psql_drop_db $migrator $admin && \
#  psql_drop_user $app $admin && \
#  psql_drop_user $migrator $admin
}

function psql_conn_local_admin() {
  local cmd=$(
    ctx_connurl_pg || return $?
    unset PGHOST
    sudo -u ${PGUSER} psql -d ${PGDATABASE}
  )
  dt_exec ${fname} "${cmd}"
}

function psql_init() { _psql_init ctx_connurl_pg ctx_connurl_pg_migrator ctx_connurl_pg_app; }
function psql_clean() { _psql_clean ctx_connurl_pg ctx_connurl_pg_migrator ctx_connurl_pg_app; }

function psql_conn_admin() { psql_conn ctx_connurl_pg; }
function psql_conn_migrator() { psql_conn ctx_connurl_pg_migrator; }
function psql_conn_app() { psql_conn ctx_connurl_pg_app; }
