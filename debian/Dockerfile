ARG base_image=debian
ARG codename=bullseye
ARG crystal_version=1.6.2
ARG llvm_version=13

# Copy the statically compiled compiler from this image
FROM --platform=$BUILDPLATFORM 84codes/crystal:latest-alpine AS alpine

FROM --platform=$BUILDPLATFORM $base_image:$codename AS builder
# add dependencies required for building crystal from source
ARG codename
ARG llvm_version
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl gnupg libgc-dev gcc g++ pkg-config make \
    libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev llvm-$llvm_version-dev

COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
# Cross compile for target architecture
ARG TARGETARCH
# Build crystal
WORKDIR /tmp/crystal
ARG crystal_version
RUN curl --retry 5 -sL https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  gzip -9 man/crystal.1 && \
  mkdir .build && \
  make crystal target=$TARGETARCH-unknown-linux-gnu PREFIX=/usr FLAGS="--release --no-debug" | tail -1 > .build/crystal.sh && \
  rm src/llvm/ext/llvm_ext.o
# Build shards
WORKDIR /tmp/shards
ARG shards_version=0.17.0
RUN curl --retry 5 -sL https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
  gzip -9 man/shards.1 man/shard.yml.5 && \
  make bin/shards FLAGS="--release --no-debug --cross-compile --target=$TARGETARCH-unknown-linux-gnu" | tail -1 > bin/shards.sh

# link on target platform
FROM $base_image:$codename AS target-builder
ARG codename
ARG llvm_version
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl gnupg gcc g++ make \
    libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev \
    autoconf automake libtool llvm-$llvm_version-dev
# build libgc
WORKDIR /tmp/libgc
ARG gc_version=8.2.2
RUN curl --retry 5 -sL https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz | \
  tar -zxf- --strip-components=1 && \
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

# build deb package
FROM --platform=$BUILDPLATFORM debian:11 AS pkg-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y ruby binutils \
    && gem install --no-document fpm
WORKDIR /tmp/pkg
# copy the binaries + stdlib + libgc from the build stages
COPY --from=builder /tmp/crystal/*.md pkg/usr/share/doc/crystal/
COPY --from=builder /tmp/crystal/man/crystal.1.gz pkg/usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shards.1.gz pkg/usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shard.yml.5.gz pkg/usr/share/man/man5/
COPY --from=builder /tmp/crystal/src pkg/usr/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal pkg/usr/bin/
COPY --from=target-builder /tmp/shards/bin/shards pkg/usr/bin/
COPY --from=target-builder /usr/lib/libgc.a pkg/usr/lib/
ARG crystal_version
ARG pkg_revision=1
ARG TARGETARCH
ARG llvm_version
RUN fpm -s dir -t deb -n crystal -v ${crystal_version} --iteration ${pkg_revision} -a ${TARGETARCH} \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends libpcre3-dev --depends pkg-config --depends libevent-dev \
  --depends llvm-$llvm_version --depends libz-dev \
  --deb-recommends libssl-dev --deb-recommends libxml2-dev \
  --deb-recommends libgmp-dev --deb-recommends libyaml-dev \
  --deb-recommends git --deb-recommends libffi-dev \
  --license "Apache 2.0" --chdir pkg .

# put .deb file in a scratch image for exporting
FROM scratch AS pkgs
COPY --from=pkg-builder /tmp/pkg/*.deb .

# start from a clean image
FROM $base_image:$codename
ARG codename
ARG llvm_version
# add dependencies commonly required for building crystal applications
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl gnupg gcc make git pkg-config \
    libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev libffi-dev llvm-$llvm_version && \
    rm -rf /var/lib/apt/lists/*
# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /tmp/crystal/*.md /usr/share/doc/crystal/
COPY --from=builder /tmp/crystal/man/crystal.1.gz /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shards.1.gz /usr/share/man/man1/
COPY --from=builder /tmp/shards/man/shard.yml.5.gz /usr/share/man/man5/
COPY --from=builder /tmp/crystal/src /usr/share/crystal/src
COPY --from=target-builder /tmp/crystal/.build/crystal /usr/bin/
COPY --from=target-builder /tmp/shards/bin/shards /usr/bin/
COPY --from=target-builder /usr/lib/libgc.a /usr/lib/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
