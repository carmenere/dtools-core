# Conventions
#   DT_AUTOCOMPLETE - an array that contains all autocomplete functions
#   DT_AUTOCOMPLETIONS[%autocomplete_function_name%] - an associative array that contains completion words for appropriate autocomplete function
#   autocomplete_%xxx% - custom autocomplete function, by default it gets name "autocomplete_methods_%xxx%"
#   methods_%xxx% - methods to be bound to autocomplete_%xxx%

autocomplete_init() {
  unset DT_AUTOCOMPLETIONS
  declare -xA DT_AUTOCOMPLETIONS
  DT_AUTOCOMPLETE=()
}

dt_gen_autocomplete() {
  local func autocomplete=$1 methods=$2 fname=dt_gen_autocomplete
  if [ -z "${methods}" ]; then dt_error ${fname} "Methods for autocomplete binding was not provided"; return 99; fi && \
  if [ -z "${autocomplete}" ]; then dt_error ${fname} "Name for autocomplete function was not provided"; return 99; fi && \
  func="${autocomplete}() {
  local cur_word="\${COMP_WORDS\[COMP_CWORD\]}"
  local options=\"\${DT_AUTOCOMPLETIONS[\"${methods}\"]}\"
  COMPREPLY=( \$(compgen -W \"\${options}\" -- \"\${cur_word}\") ); }" && \
  dt_debug ${fname} "Generating autocomplete function ${BOLD}${autocomplete}${RESET} ..." && \
  eval "$(echo -e "${func}")" && \
  dt_debug ${fname} "done"
}

dt_autocomplete() {
  local methods autocomplete fname=dt_gen_autocomplete
  methods="$1" && \
  if [ -z "${methods}" ]; then dt_error ${fname} "Methods for autocomplete binding was not provided"; return 99; fi && \
  autocomplete="autocomplete_${methods}" && \
  if ! declare -f "${methods}" >/dev/null 2>&1; then dt_error ${fname} "Function ${BOLD}${methods}${RESET} doesn't exist"; return 99; fi && \
  dt_gen_autocomplete "${autocomplete}" "${methods}" && \
  dt_debug ${fname} "Binding autocomplete function ${BOLD}${autocomplete}${RESET} to methods of group ${BOLD}${methods}${RESET}" && \
  methods=($(echo "$(${methods})")) && \
  for m in ${methods[@]}; do
    exec_cmd complete -F "${autocomplete}" "${m}" || return $?
  done && \
  dt_debug ${fname} "done"
}

dt_autocomplete_all() {
  . ${DT_VARS}/autocompletions.sh && \
  for f in ${DT_AUTOCOMPLETE[@]}; do
    dt_autocomplete "${f}" || return $?
  done
}