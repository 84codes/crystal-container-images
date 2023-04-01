ARG alpine_version=latest

FROM --platform=$BUILDPLATFORM alpine:$alpine_version AS builder
ARG llvm_version=14
# add dependencies required for building crystal from source
RUN apk add --update --no-cache \
    crystal shards \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-dev pcre2-dev libevent-static \
    libffi-dev git g++ make automake libtool autoconf curl
# Cross compile for target architecture
ARG TARGETARCH
# Build crystal
WORKDIR /tmp/crystal
ARG crystal_version=1.7.3
RUN git clone --depth=1 --single-branch --branch=$crystal_version https://github.com/crystal-lang/crystal.git . && \
  gzip -9 man/crystal.1 && \
  mkdir .build && \
  make crystal static=1 release=1 target=$TARGETARCH-alpine-linux-musl PREFIX=/usr FLAGS="--no-debug -Duse_pcre2" | tail -1 > .build/crystal.sh && \
  rm src/llvm/ext/llvm_ext.o
# Build shards
WORKDIR /tmp/shards
ARG shards_version=0.17.2
RUN git clone --depth=1 --single-branch --branch=v${shards_version} https://github.com/crystal-lang/shards.git . && \
  gzip -9 man/shards.1 man/shard.yml.5 && \
  make bin/shards static=1 release=1 FLAGS="--no-debug --cross-compile --target=$TARGETARCH-alpine-linux-musl -Duse_pcre2" | tail -1 > bin/shards.sh

# link on target platform
FROM alpine:$alpine_version AS target-builder
ARG llvm_version=14
RUN apk add --update --no-cache \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-static pcre-dev pcre2-dev libevent-static \
    libffi-dev git g++ make automake libtool autoconf curl
# Build libgc
WORKDIR /tmp/libc
ARG gc_version=8.2.2
RUN git clone --depth=1 --single-branch --branch=v${gc_version} https://github.com/ivmai/bdwgc.git . && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -fPIE -O3" && \
  make install
# Link crystal
WORKDIR /tmp/crystal
COPY --from=builder /tmp/crystal/Makefile .
COPY --from=builder /tmp/crystal/src/llvm/ext src/llvm/ext
COPY --from=builder /tmp/crystal/.build .build
RUN make llvm_ext
RUN sh -ex .build/crystal.sh && strip .build/crystal
# Link shards
WORKDIR /tmp/shards
COPY --from=builder /tmp/shards/bin bin
RUN sh -ex bin/shards.sh && strip bin/shards

# start from a clean image
FROM alpine:$alpine_version
# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre-dev pcre2-dev libevent-dev libevent-static openssl1.1-compat-dev openssl1.1-compat-libs-static libxml2-dev zlib-dev zlib-static git make yaml-dev libxml2-static
# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /tmp/crystal/*.md /usr/share/doc/crystal/
COPY --from=builder /tmp/crystal/man/crystal.1.gz /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shards.1.gz /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shard.yml.5.gz /usr/share/man/man5/
COPY --from=builder /tmp/crystal/src /usr/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal /usr/bin/
COPY --from=target-builder /tmp/shards/bin/shards /usr/bin/
COPY --from=target-builder /usr/lib/libgc.a /usr/lib/crystal/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
