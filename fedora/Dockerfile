ARG base_image=fedora
ARG base_image_tag=latest
ARG crystal_version=1.4.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine-latest AS alpine

# Build libgc
FROM $base_image:$base_image_tag AS libgc-builder
RUN dnf install -y --nodocs gcc make wget autoconf automake libtool && \
    dnf clean all
WORKDIR /tmp/libgc
ARG gc_version=8.2.0
RUN curl --retry 5 -sL https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install

# Resulting image
FROM $base_image:$base_image_tag
RUN dnf install -y --nodocs \
        gcc make git libevent-devel \
        pcre-devel libxml2-devel libyaml-devel \
        openssl-devel zlib-devel && \
    dnf clean all
COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
COPY --from=alpine /usr/share/doc/crystal /usr/share/doc/crystal
COPY --from=alpine /usr/share/man/man1/crystal.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man1/shards.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man5/shard.yml.5 /usr/share/man/man5/
COPY --from=libgc-builder /usr/lib64/libgc.a /usr/lib64/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
