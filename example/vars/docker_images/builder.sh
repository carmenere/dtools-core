. ${DT_VARS}/docker_images/defaults.sh

DOCKERFILE="${DT_CORE}/dockerfiles/Dockerfile.rust"
COMMAND="/bin/bash"
CTX="${DT_PROJECT}"

PG_MAJOR="$(. ${DT_VARS}/services/pg_17.sh && echo ${MAJOR})"
RUSTUP_TOOLCHAIN="$(. ${DT_VARS}/rustup/1.86.0.sh && echo ${RUSTUP_TOOLCHAIN})"

IMAGE="builder:$(docker_default_tag "rust-${RUSTUP_TOOLCHAIN}-pg-${PG_MAJOR}")"

add_build_args BASE_IMAGE "$(docker_arm64v8)alpine:3.21"
add_build_args PG_MAJOR "${PG_MAJOR}"

LOCALS=${DT_LOCAL_VARS}/docker_images/builder.sh
source_locals ${LOCALS}