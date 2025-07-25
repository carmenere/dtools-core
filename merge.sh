merge_conn() {
  mvar USER $(pg_superuser)
  mvar PASSWORD "postgres"
  mvar DATABASE "postgres"
  mvar HOST "localhost"
  mvar PORT 0
  mvar MODE $(pg_mode)
}

merge_socket() {
  mvar PORT 0
  mvar HOST "localhost"
  mvar PROTO "tcp"
}
