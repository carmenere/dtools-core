brew_start() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services start "${OS_SERVICE}"
)}

brew_stop() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services stop "${OS_SERVICE}"
)}

brew_restart() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services restart "${OS_SERVICE}"
)}

brew_show() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services info "${OS_SERVICE}" --json
)}

brew_show_all() { exec_cmd brew services list; }

##################################################### AUTOCOMPLETE #####################################################
cmd_family_brew() {
  local methods=()
  methods+=(brew_start)
  methods+=(brew_stop)
  methods+=(brew_restart)
  methods+=(brew_show)
  methods+=(brew_show_all)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_brew"
