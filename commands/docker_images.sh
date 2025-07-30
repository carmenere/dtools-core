function ctx_rust_builder() {
  ctx_pg_host && ctx_rustup && \
  local caller ctx=$(fname "${FUNCNAME[0]}" "$0"); set_caller $1; if is_cached; then return 0; fi && \
  ctx_rustup ${caller} && \
  var BASE_IMAGE "$(docker_arm64v8)alpine:3.21" && \
  var SERVICE "builder-$(RUSTUP_TOOLCHAIN ctx_rustup)" && \
  var IMAGE "builder:$(docker_default_tag "rust-$(RUSTUP_TOOLCHAIN ctx_rustup)-pg-$(MAJOR ctx_pg_host)")" && \
  var PG_MAJOR "$(MAJOR ctx_pg_host)" && \
  var BUILD_ARGS "BASE_IMAGE PG_MAJOR" && \
  var DOCKERFILE "${DT_CORE}/docker/Dockerfile.rust" && \
  var COMMAND "/bin/bash" && \
  var FLAGS "-ti" && \
  var RM "--rm" && \
  var RESTART "no" && \
  ctx_docker_network ${caller} && ctx_docker_service ${caller} && \
  cache_ctx
}

DT_BINDINGS+=(ctx_rust_builder:builder_rust:docker_methods)
