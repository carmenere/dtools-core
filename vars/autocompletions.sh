SERVICES=("pg" "clickhouse" "redis" "rabbitmq")

autocomplete_add cmd_family_brew ${SERVICES[@]}
autocomplete_add cmd_family_systemctl ${SERVICES[@]}
autocomplete_add cmd_family_service ${SERVICES[@]}
autocomplete_add cmd_family_pg_services "pg" "pg_ctl"
autocomplete_add cmd_family_clickhouse_install "clickhouse"
autocomplete_add cmd_family_rabbitmq_install "rabbitmq"
autocomplete_add cmd_family_redis_install "redis"
autocomplete_add cmd_family_docker_image ${SERVICES[@]} "builder"
autocomplete_add cmd_family_docker_network "example"
autocomplete_add cmd_family_docker_service ${SERVICES[@]}
autocomplete_add cmd_family_dump_restore "admin" "migrator" "app"
autocomplete_add cmd_family_psql "admin" "migrator" "app"
autocomplete_add cmd_family_psql_batch "pg"

autocomplete_add cmd_family_m4_psql_query \
  "alter_role_password.sql" "drop_role_password.sql" "create_user.sql" "drop_user.sql" "create_db.sql" "drop_db.sql" \
  "grant_user_migrator.sql" "revoke_user_migrator.sql" "grant_user_app.sql" "revoke_user_app.sql"

autocomplete_add cmd_family_sqlx "tetrix"
autocomplete_add cmd_family_cargo_crates "sqlx" "cargo_audit" "cargo_cyclonedx" "cargo_deny" "cargo_sonar"
autocomplete_add cmd_family_cargo_workspace "tetrix"
autocomplete_add cmd_family_cargo_package "tetrix"
autocomplete_add cmd_family_rustup "1.86"
autocomplete_add cmd_family_cargo_ssdlc "tetrix"
autocomplete_add cmd_family_app "tetrix"
autocomplete_add cmd_family_tmux "tetrix"

autocomplete_add cmd_family_m4_clickhouse_query \
  "create_user.sql" "drop_user.sql" "create_db.sql" "drop_db.sql" "grant_user_migrator.sql" "revoke_user_migrator.sql"

autocomplete_add cmd_family_clickhouse_batch "clickhouse"
autocomplete_add cmd_family_clickhouse "admin" "app"
autocomplete_add cmd_family_m4_clickhouse "clickhouse"
autocomplete_add cmd_family_redis_batch "redis"
autocomplete_add cmd_family_redis "admin" "app"
autocomplete_add cmd_family_rabbitmq_batch "rabbitmq"
autocomplete_add cmd_family_rabbitmq "app"
autocomplete_add cmd_family_python "3.9.11"
autocomplete_add cmd_family_curl "version"
