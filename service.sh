merge_service() {
  mvar MODE $(pg_mode)
  mref HOST "os_services" pg
  mref DOCKER "docker_services" "$(echo $(HOST) | cut -d':' -f 2)"
  if [ "$(MODE)" = "host" ]; then
    mvar SERVICE "$(echo $(HOST) | cut -d':' -f 2)"
    mvar SOCK_PUB $(SOCK_PUB $(HOST))
    mvar SOCK $(SOCK $(HOST))
    mvar CLIENT $(CLIENT $(HOST))
    mvar CHECK $(CHECK $(HOST))
    mvar EXEC $(EXEC $(HOST))
    mvar TERMINAL $(TERMINAL $(HOST))
  elif [ "$(MODE)" = "docker" ]; then
    mvar SERVICE "$(echo $(DOCKER) | cut -d':' -f 2)"
    mvar SOCK_PUB $(SOCK_PUB $(DOCKER))
    mvar SOCK $(SOCK $(DOCKER))
    mvar CLIENT $(CLIENT $(DOCKER))
    mvar CHECK $(CHECK $(DOCKER))
    local docker_exec=$(EXEC $(DOCKER))_$(SERVICE)
    eval "${docker_exec}() { $(EXEC $(DOCKER)) $(SERVICE) \$@ }"
    mvar EXEC ${docker_exec}
    local docker_terminal=$(TERMINAL $(DOCKER))_$(SERVICE)
    eval "${docker_terminal}() { $(TERMINAL $(DOCKER)) $(SERVICE) \$@ }"
    mvar TERMINAL ${docker_terminal}
  fi
}

#docker_exec_it_cmd