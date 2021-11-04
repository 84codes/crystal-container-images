ARG base_image=fedora
ARG base_image_tag=latest
ARG crystal_version=1.2.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine-latest AS builder

FROM $base_image:$base_image_tag
RUN dnf install -y --nodocs \
        gcc make git libevent-devel \
        pcre-devel libxml2-devel libyaml-devel \
        openssl-devel zlib-devel \
        wget autoconf automake libtool && \
    dnf clean all

COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal

ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# Build libgc
WORKDIR /tmp
ARG gc_version=8.0.6
RUN wget https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz && \
  tar zxf v${gc_version}.tar.gz && \
  cd bdwgc-${gc_version} && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config && \
  make -j$(nproc) CFLAGS=-DNO_GETCONTEXT && \
  make install && \
  cd .. && \
  rm -r * && \
  dnf remove -y wget autoconf automake libtool
WORKDIR /

# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
