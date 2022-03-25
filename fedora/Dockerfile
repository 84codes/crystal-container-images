ARG base_image=fedora
ARG base_image_tag=latest
ARG crystal_version=1.3.2

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
  ./configure --disable-debug --disable-shared --enable-large-config && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install

# Resulting image
FROM $base_image:$base_image_tag
RUN dnf install -y --nodocs \
        gcc make git libevent-devel \
        pcre-devel libxml2-devel libyaml-devel \
        openssl-devel zlib-devel && \
    dnf clean all
COPY --from=alpine /usr/local/bin/shards /usr/local/bin/
COPY --from=alpine /usr/local/bin/crystal /usr/local/bin/
COPY --from=alpine /usr/local/share/crystal /usr/local/share/crystal
COPY --from=libgc-builder /usr/local/lib/libgc.a /usr/local/lib/
ENV CRYSTAL_LIBRARY_PATH=/usr/local/lib
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
