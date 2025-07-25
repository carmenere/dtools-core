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
}
