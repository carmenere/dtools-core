app_envs() { echo "$(inline_vars "$(APP_ENVS)")"; }

function app_start() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  non_empty=(APP BINARY LOG_FILE)
  for v in ${non_empty[@]}; do if [ -z "$(${v})" ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; fi; done
  if [ -n "$(LOG_FILE)" ] && [ ! -d "$(dirname $(LOG_FILE))" ]; then mkdir -p $(dirname "$(LOG_FILE)"); fi
  exec_cmd $(app_envs) $(BINARY) $(OPTS) 2\>\&1 \| tee -a $(LOG_FILE)
}

function app_stop() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  non_empty=(APP PKILL_PATTERN)
  for v in ${non_empty[@]}; do if [ -z "$(${v})" ]; then dt_error ${fname} "Var ${BOLD}${v}${RESET} is empty"; fi; done
  dt_info ${fname} "Sending signal 'KILL' to ${BOLD}$(APP)${RESET} ..."
  exec_cmd "ps -A -o pid,args | grep -v grep | grep '$(PKILL_PATTERN)' | awk '{print \$1}' | xargs -I {} kill -s 'KILL' {}"
  dt_info ${fname} "${BOLD}done${RESET}"
}

function app_methods() {
  local methods=()
  methods+=(app_stop)
  methods+=(app_start)
  echo "${methods[@]}"
}

function ctx_app() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); dt_debug ${ctx} ">>>>> ctx=${ctx}, caller=?????"; set_caller $1; if is_cached; then return 0; fi
  var APP
  var APP_ENVS
  var BINARY
  var OPTS
  var LOG_FILE "${DT_LOGS}/$(APP).logs"
  var PKILL_PATTERN
  cache_ctx
}
