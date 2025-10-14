cargo_deps() {
  rustup_init 1.90.0
  cargo_install cargo_audit
  cargo_install cargo_cyclonedx
  cargo_install cargo_deny
  cargo_install cargo_sonar
  cargo_install sqlx
}

install_services() {
  install_postgres pg
  psql_alter_role_password pg admin
}

prepare_services() {
  pg_prepare pg
  ch_prepare clickhouse
}

up() {
  app_stop tetrix
  tmux_kill
  service_start pg
  psql_clean pg
  psql_init pg
  sqlx_run tetrix
  psql_grant_user pg app
  cargo_clippy package tetrix
  cargo_fmt package tetrix
  cargo_build package tetrix
  tmux_start tetrix
  sleep_2
  cargo_test package tetrix
}

down() {
  app_stop tetrix
  tmux_kill
}
