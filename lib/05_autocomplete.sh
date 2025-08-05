# Conventions
#   DT_AUTOCOMPLETE - an array that contains all registered functions cmd_family_%xxx%
#   DT_AUTOCOMPLETIONS_%xxx% - an array that contains completion words for appropriate autocomplete function autocomplete_%xxx%
#   autocomplete_%xxx% - some autocomplete function
#   cmd_family_%xxx% - function that return list of all commands that share the same autocomplete function autocomplete_%xxx%

autocomplete_init() {
  unset DT_AUTOCOMPLETIONS
  declare -xA DT_AUTOCOMPLETIONS
  DT_AUTOCOMPLETE=()
}

autocomplete_reg_family() {
  DT_AUTOCOMPLETE+=($1)
  eval "DT_AUTOCOMPLETIONS["$1"]="
}

autocomplete_add() {
  local cmd_family=$1
  shift
  eval "DT_AUTOCOMPLETIONS[${cmd_family}]=\"${DT_AUTOCOMPLETIONS[${cmd_family}]} $@\""
}

dt_bind_autocomplete_to_commnads() {
  local func commands cmd_family autocomplete fname=dt_gen_autocomplete
  cmd_family="$1" && \
  if [ -z "${cmd_family}" ]; then dt_error ${fname} "Command family was not provided"; return 99; fi && \
  if ! declare -f "${cmd_family}" >/dev/null 2>&1; then dt_error ${fname} "Function ${BOLD}${cmd_family}${RESET} doesn't exist"; return 99; fi && \
  autocomplete="autocomplete_${cmd_family}" && \
  func="${autocomplete}() {
  local cur_word="\${COMP_WORDS\[COMP_CWORD\]}"
  local options=\"\${DT_AUTOCOMPLETIONS[${cmd_family}]}\"
  COMPREPLY=( \$(compgen -W \"\${options}\" -- \"\${cur_word}\") ); }" && \
  dt_debug ${fname} "Generating autocomplete function ${BOLD}${autocomplete}${RESET} ..." && \
  eval "$(echo -e "${func}")" || return $?
  dt_debug ${fname} "done"
  dt_debug ${fname} "Binding autocomplete function ${BOLD}${autocomplete}${RESET} to cmd_family ${BOLD}${cmd_family}${RESET}"
  commands=($(echo "$(${cmd_family})")) && \
  for cmd in ${commands[@]}; do
    exec_cmd complete -F "${autocomplete}" "${cmd}" || return $?
  done && \
  dt_debug ${fname} "done"
}

dt_autocomplete() {
  . ${DT_VARS}/autocompletions.sh && \
  for f in ${DT_AUTOCOMPLETE[@]}; do
    dt_bind_autocomplete_to_commnads "${f}" || return $?
  done
}