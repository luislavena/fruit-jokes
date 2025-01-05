# ---
# build

FROM ghcr.io/luislavena/hydrofoil-crystal:1.14 AS build

WORKDIR /build

COPY ./shard.yml ./shard.lock /build/

RUN --mount=type=cache,target=/root/.cache \
    set -eux -o pipefail; \
    shards check || shards install

COPY . /build/

RUN --mount=type=cache,target=/root/.cache \
    set -eux -o pipefail; \
    shards build --release --static fruit-jokes

# ---
# final image

FROM registry.docker.com/library/alpine:3.21.0

# upgrade system and installed dependencies for security patches
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    set -eux; \
    apk upgrade

COPY --from=build /build/bin/fruit-jokes /usr/bin/

EXPOSE 3000

CMD ["/usr/bin/fruit-jokes"]
