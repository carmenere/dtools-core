select_service_rmq() {
  if [ "${PROFILE_RMQ}" = "docker" ]; then echo "ctx_docker_rmq"; else echo "ctx_service_rmq"; fi
}

rmq_host() { if [ -n "$(RABBIT_HOST)" ]; then echo "--host $(RABBIT_HOST)"; fi; }
rmq_port() { if [ -n "$(RABBIT_PORT_MGM)" ]; then echo "--port $(RABBIT_PORT_MGM)"; fi; }
rmq_user() { if [ -n "$(RABBIT_USER)" ]; then echo "--username $(RABBIT_USER)"; fi; }
rmq_password() { if [ -n "$(RABBIT_PASSWORD)" ]; then echo "--password $(RABBIT_PASSWORD)"; fi; }

_rabbitmqadmin_conn_cmd() {
  echo "rabbitmqadmin $(rmq_host) $(rmq_port) $(rmq_user) $(rmq_password)"
}

rabbitmqctl_check_user() { echo "${SUDO} rabbitmqctl --quiet list_users | sed -n '1d;p' | cut -d$'\t' -f1 | grep -m 1 '^$(RABBIT_USER)$'"; }
rabbitmqctl_create_user() { echo "${SUDO} rabbitmqctl add_user $(RABBIT_USER) $(RABBIT_PASSWORD)"; }
rabbitmqctl_drop_user() { echo "${SUDO} rabbitmqctl delete_user $(RABBIT_USER)"; }
rabbitmqctl_set_user_tags() { echo "${SUDO} rabbitmqctl set_user_tags $(RABBIT_USER) administrator"; }
rabbitmqctl_set_permissions() { echo "${SUDO} rabbitmqctl set_permissions -p / $(RABBIT_USER) '.*' '.*' '.*'"; }

rabbitmqadmin_delete() {
  local fname conn query_ctx=$1 conn_ctx=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "query_ctx=${query_ctx}, conn_ctx=${conn_ctx}, exec=${exec}" && \
  err_if_empty ${fname} "query_ctx conn_ctx exec" && \
  ${conn_ctx} && \
  conn="$(switch_ctx ${conn_ctx} && _rabbitmqadmin_conn_cmd)" && \
  ${query_ctx} && \
  (
    switch_ctx ${query_ctx} && \
    queues=($(echo "$(QUEUES)"))
    dt_debug ${fname} "queues=${queues[@]}"
    for queue in ${queues[@]}; do
      ${exec} "${conn} delete queue name='${queue}' || true"
    done
    exchanges=($(echo "$(EXCHANGES)"))
    for exchange in ${exchanges[@]}; do
      ${exec} "${conn} delete exchange name='${exchange}' || true"
    done
  )
}

_rmq_init() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  if ! ${exec} "$(switch_ctx ${app} && rabbitmqctl_check_user)"; then
    ${exec} "$(switch_ctx ${app} && rabbitmqctl_create_user)" && \
    ${exec} "$(switch_ctx ${app} && rabbitmqctl_set_user_tags)" && \
    ${exec} "$(switch_ctx ${app} && rabbitmqctl_set_permissions)"
  fi
}

_rmq_clean() {
  local admin=$1 app=$2 exec=$3 fname=$(fname "${FUNCNAME[0]}" "$0")
  dt_debug ${fname} "admin=${admin}, app=${app}, exec=${exec}" && \
  err_if_empty ${fname} "admin app exec" && \
  ${admin} && ${app} && \
  if ${exec} "$(switch_ctx ${app} && rabbitmqctl_check_user)"; then
    ${exec} "$(switch_ctx ${app} && rabbitmqctl_drop_user)" && \
    rabbitmqadmin_delete ${app} ${admin} ${exec}
  fi
}
