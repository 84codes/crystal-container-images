ARG alpine_version=latest
FROM --platform=$BUILDPLATFORM alpine:edge AS builder
ARG llvm_version=13
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
ARG crystal_version=1.4.1
RUN curl --retry 5 -sL https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  mkdir .build && \
  make crystal static=1 release=1 target=$TARGETARCH-alpine-linux-musl PREFIX=/usr FLAGS="--no-debug" | tail -1 > .build/crystal.sh && \
  rm src/llvm/ext/llvm_ext.o
# Build shards
WORKDIR /tmp/shards
ARG shards_version=0.17.0
RUN curl --retry 5 -sL https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  make bin/shards static=1 release=1 FLAGS="--no-debug --cross-compile --target=$TARGETARCH-alpine-linux-musl" | tail -1 > bin/shards.sh

# link on target platform
FROM alpine:edge AS target-builder
ARG llvm_version=13
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
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
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

# build deb and rpm packages
FROM debian:11 AS pkg-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl gcc g++ make libc-dev autoconf automake libtool ruby rpm binutils \
    && gem install fpm
# build libgc
WORKDIR /tmp/libgc
ARG gc_version=8.2.0
RUN curl --retry 5 -sL https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz | \
  tar -zxf- --strip-components=1
RUN ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install
# build distribution packages
WORKDIR /tmp/pkg
COPY --from=builder /tmp/crystal/*.md pkg/usr/share/doc/crystal/
COPY --from=builder /tmp/crystal/man/crystal.1 pkg/usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shards.1 pkg/usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shard.yml.5 pkg/usr/share/man/man5/
COPY --from=builder /tmp/crystal/src pkg/usr/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal pkg/usr/bin/
COPY --from=target-builder /tmp/shards/bin/shards pkg/usr/bin/
RUN mkdir -p pkg/usr/lib && cp /usr/lib/libgc.a pkg/usr/lib/
ARG crystal_version=1.4.1
ARG pkg_revision=1
RUN fpm -s dir -t deb -n crystal -v ${crystal_version} --iteration ${pkg_revision} -a native \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends libpcre3-dev --depends pkg-config --depends libevent-dev \
  --deb-recommends libssl-dev --deb-recommends libz-dev --deb-recommends libxml2-dev \
  --deb-recommends libgmp-dev --deb-recommends libyaml-dev --deb-recommends git \
  --license "Apache 2.0" --chdir pkg .
RUN fpm -s dir -t rpm -n crystal -v ${crystal_version} --iteration ${pkg_revision} -a native \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends pcre-devel --depends pkgconfig --depends libevent-devel \
  --depends gmp-devel --depends openssl-devel --depends libxml2-devel \
  --depends libyaml-devel --depends zlib-devel \
  --license "APL 2.0" --chdir pkg .

# put .deb file in a scratch image for exporting
FROM scratch AS pkgs
COPY --from=pkg-builder /tmp/pkg/*.deb /tmp/pkg/*.rpm .

# start from a clean image
FROM alpine:$alpine_version
# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git make yaml-dev
# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /tmp/crystal/*.md /usr/share/doc/crystal/
COPY --from=builder /tmp/crystal/man/crystal.1 /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shards.1 /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shard.yml.5 /usr/share/man/man5/
COPY --from=builder /tmp/crystal/src /usr/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal /usr/bin/
COPY --from=target-builder /tmp/shards/bin/shards /usr/bin/
COPY --from=target-builder /usr/lib/libgc.a /usr/lib/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
