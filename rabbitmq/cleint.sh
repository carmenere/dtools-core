rmq_host() { if [ -n "$(RMQ_HOST)" ]; then echo "--host $(RMQ_HOST)"; fi; }
rmq_port() { if [ -n "$(PORT_MGM)" ]; then echo "--port $(PORT_MGM)"; fi; }
rmq_user() { if [ -n "$(RMQ_USER)" ]; then echo "--username $(RMQ_USER)"; fi; }
rmq_password() { if [ -n "$(RMQ_PASSWORD)" ]; then echo "--password $(RMQ_PASSWORD)"; fi; }

_rabbitmqadmin_conn() { echo "rabbitmqadmin $(rmq_host) $(rmq_port) $(rmq_user) $(rmq_password)"; }
_rabbitmqctl_conn() { echo "rabbitmqctl $@"; }

rmq_conn() { $(TERMINAL) "$(_rabbitmqctl_conn $@)"; }

rmq_check_user() { $(EXEC) "${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^$(RMQ_USER)$'"; }
rmq_create_user() { $(EXEC) "${SUDO} rabbitmqctl add_user $(RMQ_USER) $(RMQ_PASSWORD)"; }
rmq_drop_user() { $(EXEC) "${SUDO} rabbitmqctl delete_user $(RMQ_USER)"; }
rmq_set_user_tags() { $(EXEC) "${SUDO} rabbitmqctl set_user_tags $(RMQ_USER) administrator"; }
rmq_set_permissions() { $(EXEC) "${SUDO} rabbitmqctl set_permissions -p / $(RMQ_USER) '.*' '.*' '.*'"; }

rmq_delete() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local queues=($(echo "$(QUEUES)")) exchanges=($(echo "$(EXCHANGES)"))
  switch_ctx $(CONN) && \
  local conn="$(_rabbitmqadmin_conn)" && \
  dt_debug ${fname} "conn=$(CONN), queues=$(QUEUES), exchanges=$(EXCHANGES), conn=${conn}" && \
  (
    for queue in ${queues[@]}; do
      $(EXEC) "${conn} delete queue name='${queue}' || true"
    done
    for exchange in ${exchanges[@]}; do
      $(EXEC) "${conn} delete exchange name='${exchange}' || true"
    done
  )
}

function _rmq_init() {
  local app="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "app=${app}" && \
  err_if_empty ${fname} "app" && \
  if ! ${app}__rmq_check_user; then
    ${app}__rmq_create_user && \
    ${app}__rmq_set_user_tags && \
    ${app}__rmq_set_permissions
  fi
}

function _rmq_clean() {
  local app="$1" fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "app=${app}" && \
  err_if_empty ${fname} "app" && \
  if ${app}__rmq_check_user; then
    ${app}__rmq_drop_user && \
    ${app}__rmq_delete
  fi
}

rmq_methods() {
  local methods=()
  methods+=(rmq_conn)
  methods+=(rmq_check_user)
  methods+=(rmq_create_user)
  methods+=(rmq_drop_user)
  methods+=(rmq_set_user_tags)
  methods+=(rmq_set_permissions)
  methods+=(rmq_delete)
  echo "${methods[@]}"
}
