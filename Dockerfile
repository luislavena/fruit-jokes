# ---
# build

FROM ghcr.io/luislavena/hydrofoil-crystal:1.15 AS build

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

FROM registry.docker.com/library/alpine:3.21.2

# upgrade system and installed dependencies for security patches
RUN --mount=type=cache,target=/var/cache/apk \
    set -eux; \
    apk upgrade

# install litestream
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    cd /tmp; \
    { \
        export LITESTREAM_VERSION=0.3.13; \
        case "$(arch)" in \
        x86_64) \
            export \
                LITESTREAM_ARCH=amd64 \
                LITESTREAM_SHA256=eb75a3de5cab03875cdae9f5f539e6aedadd66607003d9b1e7a9077948818ba0 \
            ; \
            ;; \
        aarch64) \
            export \
                LITESTREAM_ARCH=arm64 \
                LITESTREAM_SHA256=9585f5a508516bd66af2b2376bab4de256a5ef8e2b73ec760559e679628f2d59 \
            ; \
            ;; \
        esac; \
        wget -q -O litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-${LITESTREAM_ARCH}.tar.gz; \
        echo "${LITESTREAM_SHA256} *litestream.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf litestream.tar.gz; \
        mv litestream /usr/local/bin/; \
        rm -f litestream.tar.gz; \
    }; \
    # smoke test
    [ "$(command -v litestream)" = '/usr/local/bin/litestream' ]; \
    litestream version

COPY ./container/litestream.yml /etc/
COPY ./container/entrypoint.sh /

COPY --from=build /build/bin/fruit-jokes /usr/bin/

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
