ARG base_image=fedora
ARG base_image_tag=34
ARG crystal_version

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine-latest AS builder

FROM $base_image:$base_image_tag
RUN dnf install -y --nodocs \
        gcc make git gc-devel libevent-devel \
        pcre-devel libxml2-devel libyaml-devel \
        openssl-devel zlib-devel && \
    dnf clean all

COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal

ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src