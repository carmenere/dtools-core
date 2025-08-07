# RESTART = {no|always|unless-stopped}

declare -A run_envs
BRIDGE=example
COMMAND=
FLAGS=-d
PUBLISH=
RESTART=unless-stopped
RM=
RUN_ENVS=()
EXEC="docker_exec_i"
TERMINAL="docker_exec_it"
