# RESTART = {no|always|unless-stopped}

unset run_envs
declare -A run_envs
RUN_ENVS=()

BRIDGE=example
COMMAND=
FLAGS=-d
PUBLISH=
RESTART=unless-stopped
RM=

EXEC="docker_exec_i"
TERMINAL="docker_exec_it"
