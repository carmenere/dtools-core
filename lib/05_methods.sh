### Consider function docker_build(), then the call "dt_register ctx_docker_pg_admin pg docker_methods"
### will generate function docker_build_pg() { dt_init_and_load_ctx && docker_build_pg }
#dt_bind() {
#  local body ctx suffix methods method excluded fname=$(fname "${FUNCNAME[0]}" "$0")
#  ctx=$(echo "$1" | cut -d':' -f 1)
#  suffix=$(echo "$1" | cut -d':' -f 2)
#  methods=$(echo "$1" | cut -d':' -f 3)
#  excluded=$(echo "$1" | cut -d':' -f 4)
#  err_if_empty ${fname} "ctx suffix methods" || return $?
#  dt_debug ${fname} "ctx=${BOLD}${ctx}${RESET}, suffix=${suffix}, methods=${methods}"
#  if [ -n "${suffix}" ]; then suffix="_${suffix}"; fi
#  if ! declare -f "${methods}" >/dev/null 2>&1; then
#    dt_error ${fname} "Function ${BOLD}${methods}${RESET} doesn't exist"
#    return 99
#  fi
#  methods=($(echo $(${methods})| sort))
#  excluded=($(echo ${excluded}))
#  if [ -n "${excluded}" ]; then dt_info ${fname} "${BOLD}excluded${RESET}=${excluded[@]}"; fi
#  for method in ${methods[@]}; do
#    if is_contained ${method}${suffix} excluded; then continue; fi && \
#    if [ declare -p ${method}${suffix} >/dev/null 2>&1 ] || [ declare -p ${ctx}__${method} >/dev/null 2>&1 ]; then
#      dt_error ${fname} "Duplicated method=${BOLD}${method}${suffix}${RESET}"
#      return 99
#    fi
#    dt_debug ${fname} "Registering methods: ${BOLD}${method}${suffix}${RESET} and ${BOLD}${ctx}__${method}${RESET}"
#    DT_METHODS+=(${method}${suffix})
#    DT_METHODS+=(${ctx}__${method})
#    body="{ local dt_ctx=\${DT_CTX}; local self=${ctx}; switch_ctx ${ctx} && ${method} \$@; local err=\$?; DT_CTX=\${dt_ctx}; return \${err}; }" && \
#    eval "function ${method}${suffix}() ${body}" && \
#    eval "function ${ctx}__${method}() ${body}" || return $?
#  done
#}
#
#dt_register() {
#  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
#  DT_BINDINGS=($(for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done | sort))
#  for binding in ${DT_BINDINGS[@]}; do dt_bind "${binding}" || return $?; done
#}
#
#dt_bindings() {
#  local binding fname=$(fname "${FUNCNAME[0]}" "$0")
#  for binding in ${DT_BINDINGS[@]}; do echo "${binding}"; done
#}
#
#dt_methods() {
#  local method fname=$(fname "${FUNCNAME[0]}" "$0")
#  DT_METHODS=($(for method in ${DT_METHODS[@]}; do echo "${method}"; done | sort))
#  for method in ${DT_METHODS[@]}; do echo "${method}"; done
#}