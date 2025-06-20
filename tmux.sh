function tmux_new() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  tmux has-session -t $(TMX_SESSION) || tmux new -s $(TMX_SESSION) -d
  tmux has-session -t $(TMX_SESSION) && \
  tmux set-option -t $(TMX_SESSION) -g default-command $(TMX_DEFAULT_CMD)
  tmux has-session -t $(TMX_SESSION) && \
  tmux set-option -t $(TMX_SESSION) -g default-terminal $(TMX_DEFAULT_TERM)
  tmux has-session -t $(TMX_SESSION) && \
  tmux set-option -t $(TMX_SESSION) -g history-limit $(TMX_HISTORY_LIMIT)
  tmux has-session -t $(TMX_SESSION) && \
  tmux set-option -t $(TMX_SESSION) -g default-size $(TMX_TERM_SIZE)
}

function tmux_close() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  tmux has-session -t $(TMX_SESSION) && tmux kill-session -t $(TMX_SESSION) || echo "Session $(TMX_SESSION) was not opened."
}

function tmux_select_window() {
  exec_cmd "tmux select-window -t $(TMX_SESSION):$(TMX_WINDOW_NAME)"
}

function tmux_new_window() {
  exec_cmd "tmux new-window -t $(TMX_SESSION) -n $(TMX_WINDOW_NAME)"
}

function tmux_start() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  tmux_new || return $?
  tmux_select_window || tmux_new_window
  exec_cmd "tmux send-keys -t $(TMX_SESSION):$(TMX_WINDOW_NAME) \"$(TMX_START_CMD)\" ENTER"
}

function tmux_stop() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  if tmux has-session -t $(TMX_SESSION); then
    exec_cmd "tmux kill-window -t $(TMX_SESSION):$(TMX_WINDOW_NAME)"
    dt_info ${fname} "stopped"
  else
    dt_info ${fname} "Window $(TMX_SESSION):$(TMX_WINDOW_NAME) was not opened."
  fi
}

function tmux_connect() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  exec_cmd "tmux a -t "$(TMX_SESSION):$(TMX_WINDOW_NAME)""
}

function tmux_kill() { exec_cmd "tmux kill-server || true"; }
function tmux_sessions() { exec_cmd "tmux ls"; }

function tmux_methods() {
  local methods=()
  methods+=(tmux_connect)
  methods+=(tmux_stop)
  methods+=(tmux_start)
  methods+=(tmux_restart)
  echo "${methods[@]}"
}

function ctx_tmux() {
  local fname=$(fname "${FUNCNAME[0]}" "$0")
  local dt_ctx; ctx_prolog ${fname} || return $?; if is_cached ${fname}; then return 0; fi
  var TMX_DEFAULT_CMD "/bin/bash"
  var TMX_DEFAULT_TERM "xterm-256color"
  var TMX_HISTORY_LIMIT 1000000
  var TMX_TERM_SIZE "240x32"
  # tmux session name
  var TMX_SESSION
  # WINDOW_NAME and START_CMD are different for each APP
  var TMX_WINDOW_NAME
  var TMX_START_CMD && \
  ctx_epilog ${fname}
}
