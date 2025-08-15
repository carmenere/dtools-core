function rmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "rabbitmq"
  else
    echo "rabbitmq-server"
  fi
}

# ctx_host_rabbitmq && install_rabbitmq
function install_rabbitmq() {(
  local fname=install_rabbitmq
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      exec_cmd "${SUDO} apt install gnupg erlang -y" && \
      exec_cmd "${SUDO} apt install rabbitmq-server -y" && \
      exec_cmd "${SUDO} sudo rabbitmq-plugins enable rabbitmq_management"
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(rmq_service)"
  else
    dt_error ${fname} "Unsupported OS: '$(os_kernel)'"
  fi
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_rabbitmq_services() {
  local methods=()
  methods+=(install_rabbitmq)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_rabbitmq_services"