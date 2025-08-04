brew_start() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services start "${SERVICE}"
)}

brew_stop() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services stop "${SERVICE}"
)}

brew_restart() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services restart "${SERVICE}"
)}

brew_show() {(
  set -eu; . "${DT_VARS}/services/$1.sh"
  exec_cmd brew services info "${SERVICE}" --json
)}

brew_show_all() { exec_cmd brew services list; }

##################################################### AUTOCOMPLETE #####################################################
methods_brew() {
  local methods=()
  methods+=(brew_start)
  methods+=(brew_stop)
  methods+=(brew_restart)
  methods+=(brew_show)
  methods+=(brew_show_all)
  echo "${methods[@]}"
}

DT_AUTOCOMPLETE+=(methods_brew)
DT_AUTOCOMPLETIONS["methods_brew"]=""
