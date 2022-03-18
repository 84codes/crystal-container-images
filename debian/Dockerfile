ARG base_image=debian
ARG base_image_tag=latest
ARG crystal_version=1.3.2

# Copy the statically compiled compiler from this image
FROM alpine:latest AS builder
RUN apk add --update --no-cache crystal shards

FROM $base_image:$base_image_tag
COPY --from=builder /usr/bin/shards /usr/local/bin/
COPY --from=builder /usr/bin/crystal /usr/local/bin/
COPY --from=builder /usr/lib/crystal/core /usr/local/share/crystal/src
ENV CFLAGS="-pipe -O3"

ARG llvm_version=11
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git \
    build-essential pkg-config libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev \
    llvm-${llvm_version}-dev \
    wget autoconf automake libtool && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*
WORKDIR /tmp

# Build crystal
ARG crystal_version=1.3.2
RUN wget https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz && \
  tar zxf ${crystal_version}.tar.gz && \
  rm ${crystal_version}.tar.gz && \
  cd crystal-${crystal_version} && \
  FLAGS=-Dwithout_playground make crystal release=1 && \
  rm src/llvm/ext/llvm_ext.o && \
  cp .build/crystal /usr/local/bin/ && \
  strip /usr/local/bin/crystal && \
  rm -r /usr/local/share/crystal && \
  mkdir /usr/local/share/crystal && \
  cp -a src /usr/local/share/crystal/ && \
  cd .. && \
  rm -r crystal-${crystal_version}
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# Build shards
ARG shards_version=0.16.0
RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  rm v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  make bin/shards release=1 && \
  cp bin/shards /usr/local/bin/ && \
  strip /usr/local/bin/shards && \
  cd .. && \
  rm -r shards-${shards_version}

# Build libgc
ARG gc_version=8.2.0
RUN wget https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz && \
  tar zxf v${gc_version}.tar.gz && \
  cd bdwgc-${gc_version} && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config && \
  make -j$(nproc) CFLAGS=-DNO_GETCONTEXT && \
  make install && \
  cd .. && \
  rm -r * && \
  apt-get remove -y --autoremove wget autoconf automake libtool
WORKDIR /

# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
