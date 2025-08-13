stand() {(
  set -eu
  local fname=stand
  . ${DT_VARS}/stands/$1.sh
  $2
  return 99
)}

##################################################### AUTOCOMPLETE #####################################################
cmd_family_stand() {
  local methods=()
  methods+=(stand)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_stand"

autocomplete_cmd_family_stand() {
  local cur prev
  local options
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  case ${COMP_CWORD} in
    1)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[cmd_family_stand]}" -- ${cur}))
      ;;
    2)
      COMPREPLY=($(compgen -W "${DT_AUTOCOMPLETIONS[${prev}]}" -- ${cur}))
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}