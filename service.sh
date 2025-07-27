merge_service() {
  mvar MODE $(pg_mode)
  mvar HOST "os_services:pg"
  mvar DOCKER "docker_services:"$(echo $(HOST) | cut -d':' -f 2)""
  if [ "$(MODE)" = "host" ]; then
    mvar SERVICE "$(HOST)"
    mvar SOCK_PUB $(SOCK_PUB $(HOST))
    mvar SOCK $(SOCK $(HOST))
    mvar CLIENT $(CLIENT $(HOST))
    mvar CHECK $(CHECK $(HOST))
    mvar EXEC $(EXEC $(HOST))
    mvar TERMINAL $(TERMINAL $(HOST))
  elif [ "$(MODE)" = "docker" ]; then
    mvar SERVICE "$(DOCKER)"
    mvar SOCK_PUB $(SOCK_PUB $(DOCKER))
    mvar SOCK $(SOCK $(DOCKER))
    mvar CLIENT $(CLIENT $(DOCKER))
    mvar CHECK $(CHECK $(DOCKER))
    mvar EXEC $(EXEC $(DOCKER))
    mvar TERMINAL $(TERMINAL $(DOCKER))
  fi
}
