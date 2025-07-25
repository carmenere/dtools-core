merge_conn() {
  mvar USER $(pg_superuser)
  mvar PASSWORD "postgres"
  mvar DATABASE "postgres"
  mref SERVICE "services" "default"
  mvar SOCK $(SOCK $(SERVICE))
  mvar SOCK_PUB $(SOCK_PUB $(SERVICE))
}

merge_socket() {
  mvar PORT 0
  mvar HOST "localhost"
  mvar PROTO "tcp"
}

# "x" at the end of "lsofx" means extended
methods_sockets() {
  local methods=()
  methods+=(lsofx)
  echo "${methods[@]}"
}