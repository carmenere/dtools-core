service_modes() {
  local vars=(docker host)
  echo "${vars[@]}"
}

MODES=($(echo $(service_modes)))

function ctx_client_docker() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var EXEC docker_exec_i_cmd && \
  var CONN docker_exec_it_cmd && \
  var CHECK docker_check && \
  cache_ctx
}

function ctx_client_host() {
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi
  var EXEC "exec_cmd" && \
  var CONN "exec_cmd" && \
  var CHECK service_check && \
  cache_ctx
}

select_ctx() {
  local ctx_prefix="$1" mode="$2" fname=$(fname "${FUNCNAME[0]}" "$0") && err_if_empty ${fname} "ctx_prefix mode" && \
  echo "${ctx_prefix}_$(${mode})"
}