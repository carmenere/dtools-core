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
  dt_err_if_empty $0 "TMX_SESSION"; exit_on_err $0 $? || return $?
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
  dt_err_if_empty $0 "TMX_SESSION"; exit_on_err $0 $? || return $?
  tmux has-session -t ${TMX_SESSION} && tmux kill-session -t ${TMX_SESSION} || echo "Session ${TMX_SESSION} was not opened."
}

function tmux_start_sync() {
  tmux_new; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMX_WINDOW_NAME"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMX_START_CMD"; exit_on_err $0 $? || return $?
  tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME} || tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}
  tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} "${TMX_START_CMD}; tmux wait-for -S 0" ENTER
  tmux wait-for 0
}

function tmux_select_window() {
  dt_exec_or_echo "tmux select-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}"
}

function tmux_new_window() {
  dt_exec_or_echo "tmux new-window -t ${TMX_SESSION} -n ${TMX_WINDOW_NAME}"
}

function tmux_start() {
  mode=$1
  tmux_new; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMX_WINDOW_NAME"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMX_START_CMD"; exit_on_err $0 $? || return $?
  tmux_select_window $mode || tmux_new_window $mode
  dt_exec_or_echo "tmux send-keys -t ${TMX_SESSION}:${TMX_WINDOW_NAME} \"${TMX_START_CMD}\" ENTER" $mode
}

function tmux_stop() {
  mode=$1
  dt_err_if_empty $0 "TMX_WINDOW_NAME"; exit_on_err $0 $? || return $?
  dt_err_if_empty $0 "TMX_START_CMD"; exit_on_err $0 $? || return $?
  if tmux has-session -t ${TMX_SESSION}; then
    dt_exec_or_echo "tmux kill-window -t ${TMX_SESSION}:${TMX_WINDOW_NAME}" $mode
    dt_info "stopped"
  else
    dt_info "Window ${TMX_SESSION}:${TMX_WINDOW_NAME} was not opened."
  fi
}

function tmux_connect() {
  dt_err_if_empty $0 "TMX_SESSION"; exit_on_err $0 $? || return $?
  tmux a -t "${TMX_SESSION}"
}

function tmux_kill() { tmux kill-server || true }
function tmux_sessions() { tmux ls }
