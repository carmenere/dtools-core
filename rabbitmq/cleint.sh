rmq_host() { if [ -n "$(RABBIT_HOST)" ]; then echo "--host $(RABBIT_HOST)"; fi; }
rmq_port() { if [ -n "$(RABBIT_PORT_MGM)" ]; then echo "--port $(RABBIT_PORT_MGM)"; fi; }
rmq_user() { if [ -n "$(RABBIT_USER)" ]; then echo "--username $(RABBIT_USER)"; fi; }
rmq_password() { if [ -n "$(RABBIT_PASSWORD)" ]; then echo "--password $(RABBIT_PASSWORD)"; fi; }

rmq_conn() { exec_cmd rabbitmqadmin $(rmq_host) $(rmq_port) $(rmq_user) $(rmq_password); }

function rabbitmqadmin_delete() {
  local rabbitmqadmin query_ctx=$1 conn_ctx=$2 fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "query_ctx conn_ctx" || return $?
  dt_debug ${fname} "conn_ctx=${conn_ctx}"
  push_ctx ${conn_ctx} && \
  rabbitmqadmin="$(cmd_echo rmq_conn)"  || return $?
  dt_debug ${fname} "query_ctx=${query_ctx}"
  push_ctx ${query_ctx} || return $?
  queues=($(echo "$(QUEUES)"))
  dt_debug ${fname} "queues=${queues[@]}"
  for queue in ${queues[@]}; do
    exec_cmd "${rabbitmqadmin} delete queue name='${queue}' || true"
  done
  exchanges=($(echo "$(EXCHANGES)"))
  for exchange in ${exchanges[@]}; do
    exec_cmd "${rabbitmqadmin} delete exchange name='${exchange}' || true"
  done
  pop_ctx
}

rabbitmqctl_check_user() { exec_cmd "${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^$(RABBIT_USER)$'"; }
rabbitmqctl_create_user() { exec_cmd "${SUDO} rabbitmqctl add_user $(RABBIT_USER) $(RABBIT_PASSWORD)"; }
rabbitmqctl_drop_user() { exec_cmd "${SUDO} rabbitmqctl delete_user $(RABBIT_USER)"; }
rabbitmqctl_set_user_tags() { exec_cmd "${SUDO} rabbitmqctl set_user_tags $(RABBIT_USER) administrator"; }
rabbitmqctl_set_permissions() { exec_cmd "${SUDO} rabbitmqctl set_permissions -p / $(RABBIT_USER) '.*' '.*' '.*'"; }
