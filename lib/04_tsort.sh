#add_deps() {
#  local ctx=$1 fname=$(fname "${FUNCNAME[0]}" "$0"); shift
#  local deps=($(echo "$@"))
#  err_if_empty ${fname} "ctx deps" && \
#  for dep in ${deps[@]}; do
#    dt_debug ${fname} "ctx=${ctx} dep=${dep}"
#    DT_DEPS+=("${ctx} ${dep}")
#  done
#}
#
#init_deps() {
#  tsort_deps | while read dep; do ${dep} || return $?;
#  done
#}
#
#tsort_deps() {
#  printf "%s\n" "${DT_DEPS[@]}" > "${DT_CTXES_DEPS}"
#  tsort "${DT_CTXES_DEPS}" | tac
#}
#
#list_deps(){ cat ${DT_CTXES_DEPS}; }
#
