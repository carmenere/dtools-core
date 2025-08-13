function rmq_service() {
  if [ "$(os_name)" = "macos" ]; then
    echo "rabbitmq"
  else
    echo "rabbitmq-server"
  fi
}

# ctx_host_rabbitmq && rabbitmq_install
function rabbitmq_install() {(
  local fname=rabbitmq_install
  set -eu; . "${DT_VARS}/services/$1.sh"
  if [ "$(os_name)" = "debian" ] || [ "$(os_name)" = "ubuntu" ]; then
      exec_cmd "${SUDO} apt install gnupg erlang -y" && \
      exec_cmd "${SUDO} apt install rabbitmq-server -y" && \
      exec_cmd "${SUDO} sudo rabbitmq-plugins enable rabbitmq_management"
  elif [ "$(os_kernel)" = "Darwin" ]; then
    exec_cmd "brew install $(rmq_service)"
  else
    echo "Unsupported OS: '$(os_kernel)'"
  fi
)}

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_rabbitmq_services() {
  local methods=()
  methods+=(rabbitmq_install)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_rabbitmq_services"