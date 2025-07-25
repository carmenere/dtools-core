merge_psql_account() {
  local tbl_conns=conns
  mref CONN "${tbl_conns}" "pg_default"
  mref ACCOUNT "${tbl_conns}" "pg_default"
  mvar grant sql_pg_grant_user_migrator
  mvar revoke sql_pg_revoke_user_migrator
  mvar CREATE $(sql_pg_create_user $(ACCOUNT))
  mvar DROP $(sql_pg_drop_user $(ACCOUNT))
  mvar GRANT $($(grant) $(ACCOUNT))
  mvar REVOKE $($(revoke) $(ACCOUNT))
  mvar CREATE_DB $(sql_pg_create_db $(ACCOUNT))
  mvar DROP_DB $(sql_pg_drop_db $(ACCOUNT))
  mvar ALTER_PASSWORD $(sql_pg_alter_role_password $(ACCOUNT))
  mvar DROP_PASSWORD $(sql_pg_drop_role_password $(ACCOUNT))
}

merge_pg_os_service() {
  mvar SERVICE $(pg_service)
  mvar BIN_DIR $(bin_dir)
  mvar PG_HBA_CONF $(pg_hba_conf)
  mvar POSTGRESQL_CONF $(postgresql_conf)
  mvar CLIENT "$(BIN_DIR)/psql"
  mvar PG_CONFIG "$(BIN_DIR)/pg_config"
  if [ ! -x "$(PG_CONFIG)" ]; then
    dt_warning ${fname} "The binary '$(PG_CONFIG)' doesn't exist" || return $?
  else
    mvar CONFIG_SHAREDIR "$($(PG_CONFIG) --sharedir)"
    mvar CONFIG_LIBDIR "$($(PG_CONFIG) --pkglibdir)" || return $?
  fi
  merge_os_service
}