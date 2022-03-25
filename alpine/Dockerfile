ARG alpine_version=latest
FROM --platform=$BUILDPLATFORM alpine:$alpine_version AS builder
ARG llvm_version=11
# add dependencies required for building crystal from source
RUN apk add --update --no-cache \
    crystal shards \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-dev pcre-dev libevent-static \
    libffi-dev git g++ make automake libtool autoconf curl
# Cross compile for target architecture
ARG TARGETARCH
# Build crystal
WORKDIR /tmp/crystal
ARG crystal_version=1.3.2
RUN curl --retry 5 -sL https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  mkdir .build && \
  make crystal static=1 target=$TARGETARCH-alpine-linux-musl FLAGS=-Dwithout_playground | tail -1 > .build/crystal.sh
# Build shards
WORKDIR /tmp/shards
ARG shards_version=0.16.0
RUN curl --retry 5 -sL https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  make bin/shards static=1 FLAGS="--cross-compile --target=$TARGETARCH-alpine-linux-musl" | tail -1 > bin/shards.sh

# link on target platform
FROM alpine:$alpine_version AS target-builder
ARG llvm_version=11
RUN apk add --update --no-cache \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-dev pcre-dev libevent-static \
    libffi-dev git g++ make automake libtool autoconf curl
# Build libgc
WORKDIR /tmp/libc
ARG gc_version=8.2.0
RUN curl --retry 5 -sL https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install
# Link crystal
WORKDIR /tmp/crystal
COPY --from=builder /tmp/crystal/Makefile .
COPY --from=builder /tmp/crystal/src/llvm/ext src/llvm/ext
COPY --from=builder /tmp/crystal/.build .build
RUN rm src/llvm/ext/llvm_ext.o && make llvm_ext
RUN sh -ex .build/crystal.sh
# Link shards
WORKDIR /tmp/shards
COPY --from=builder /tmp/shards/bin bin
RUN sh -ex bin/shards.sh

# start from a clean image
FROM alpine:$alpine_version
# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git
# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /tmp/crystal/src /usr/local/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal /usr/local/bin/
COPY --from=target-builder /tmp/shards/bin/shards /usr/local/bin/
COPY --from=target-builder /usr/local/lib/libgc.a /usr/local/lib/
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src
ENV CRYSTAL_LIBRARY_PATH=/usr/local/lib
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
