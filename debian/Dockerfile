ARG base_image=debian
ARG base_image_tag=latest
ARG crystal_version=1.2.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine-latest AS builder

FROM $base_image:$base_image_tag
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y build-essential pkg-config libpcre3-dev libevent-dev libgc-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev git && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal

ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src
