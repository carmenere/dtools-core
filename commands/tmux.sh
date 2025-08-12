function tmux_new() {(
  local fname=tmux_new
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  tmux has-session -t ${TMX_SESSION} || tmux new -s ${TMX_SESSION} -d
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-command ${TMX_DEFAULT_CMD}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-terminal ${TMX_DEFAULT_TERM}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g history-limit ${TMX_HISTORY_LIMIT}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-size ${TMX_TERM_SIZE}
)}

function tmux_close() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  local fname=tmux_close
  tmux has-session -t ${TMX_SESSION} && tmux kill-session -t ${TMX_SESSION} || echo "Session ${TMX_SESSION} was not opened."
)}

function tmux_select_window() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  exec_cmd "tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}"
)}

function tmux_new_window() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  exec_cmd "tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}"
)}

function tmux_start() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  local fname=tmux_start
  tmux_new $1 || return $?
  tmux_select_window $1 || tmux_new_window $1
  exec_cmd "tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} \"${TMX_START_CMD}\" ENTER"
)}

function tmux_stop() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  local fname=tmux_stop
  if tmux has-session -t ${TMX_SESSION}; then
    exec_cmd "tmux kill-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}"
    dt_info ${fname} "stopped"
  else
    dt_info ${fname} "Window ${TMX_SESSION}:${TMX_WINDOW_NAME} was not opened."
  fi
)}

function tmux_connect() {(
  set -eu; . "${DT_VARS}/tmux/$1.sh"
  local fname=tmux_connect
  exec_cmd "tmux a -t "${TMX_SESSION}:${TMX_WINDOW_NAME}""
)}

function tmux_kill() { exec_cmd "tmux kill-server || true"; }
function tmux_sessions() { exec_cmd "tmux ls"; }

##################################################### AUTOCOMPLETE #####################################################
function cmd_family_tmux() {
  local methods=()
  methods+=(tmux_connect)
  methods+=(tmux_stop)
  methods+=(tmux_start)
  methods+=(tmux_restart)
  echo "${methods[@]}"
}

autocomplete_reg_family "cmd_family_tmux"
