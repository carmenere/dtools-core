function ctx_tmux() {
  TMX_DEFAULT_CMD="/bin/bash"
  TMX_DEFAULT_TERM="xterm-256color"
  TMX_HISTORY_LIMIT=1000000
  TMX_TERM_SIZE="240x32"
  # tmux session name
  TMX_SESSION=
  # WINDOW_NAME and START_CMD are different for each APP
  TMX_WINDOW_NAME=
  TMX_START_CMD=
}

function tmux_new() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "TMX_SESSION" || return $?
  tmux has-session -t ${TMX_SESSION} || tmux new -s ${TMX_SESSION} -d
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-command ${TMX_DEFAULT_CMD}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-terminal ${TMX_DEFAULT_TERM}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g history-limit ${TMX_HISTORY_LIMIT}
  tmux has-session -t ${TMX_SESSION} && \
  tmux set-option -t ${TMX_SESSION} -g default-size ${TMX_TERM_SIZE}
}

function tmux_close() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "TMX_SESSION" || return $?
  tmux has-session -t ${TMX_SESSION} && tmux kill-session -t ${TMX_SESSION} || echo "Session ${TMX_SESSION} was not opened."
}

function tmux_select_window() {
  cmd_exec "tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}"
}

function tmux_new_window() {
  cmd_exec "tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}"
}

function tmux_start() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  tmux_new || return $?
  err_if_empty ${fname} "TMX_WINDOW_NAME" || return $?
  err_if_empty ${fname} "TMX_START_CMD" || return $?
  tmux_select_window || tmux_new_window
  cmd_exec "tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} \"${TMX_START_CMD}\" ENTER"
}

function tmux_stop() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  err_if_empty ${fname} "TMX_WINDOW_NAME" || return $?
  err_if_empty ${fname} "TMX_START_CMD" || return $?
  if tmux has-session -t ${TMX_SESSION}; then
    cmd_exec "tmux kill-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}"
    info "stopped"
  else
    info "Window ${TMX_SESSION}:${TMX_WINDOW_NAME} was not opened."
  fi
}

function tmux_connect() {
  err_if_empty ${fname} "TMX_SESSION" || return $?
  cmd_exec "tmux a -t "${TMX_SESSION}:${TMX_WINDOW_NAME}""
}

function tmux_kill() { cmd_exec "tmux kill-server || true"; }
function tmux_sessions() { cmd_exec "tmux ls"; }

tmux_methods=()

tmux_methods+=(tmux_connect)
tmux_methods+=(tmux_stop)
tmux_methods+=(tmux_start)
tmux_methods+=(tmux_restart)
