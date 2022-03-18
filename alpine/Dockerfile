ARG alpine_version=latest

FROM --platform=$BUILDPLATFORM alpine:$alpine_version AS builder
WORKDIR /tmp

ARG llvm_version=11
# add dependencies required for building crystal from source
RUN apk add --update --no-cache \
    crystal shards \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-dev pcre-dev libevent-static gc-dev \
    libffi-dev \
    git g++ make automake libtool autoconf wget

#ENV CFLAGS="-pipe -O3"

# Build libgc
#ARG gc_version=8.2.0
#RUN wget https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz && \
#  tar zxf v${gc_version}.tar.gz && \
#  cd bdwgc-${gc_version} && \
#  ./autogen.sh && \
#  ./configure --disable-debug --disable-shared --enable-large-config && \
#  make -j$(nproc) CFLAGS=-DNO_GETCONTEXT && \
#  make install
#ENV CRYSTAL_LIBRARY_PATH=/usr/local/lib

ARG TARGETARCH

# Build crystal
ARG crystal_version=1.3.2
RUN wget https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz && \
  tar zxf ${crystal_version}.tar.gz && \
  cd crystal-${crystal_version} && \
  FLAGS=-Dwithout_playground make crystal static=1 target=$TARGETARCH-unknown-linux-musl | tee output && \
  tail -1 output > crystal.sh

# Build shards
ARG shards_version=0.16.0
RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  shards install && \
  echo Cross compiling shards && \
  crystal build src/shards.cr --static --release --no-debug --cross-compile --target $TARGETARCH-unknown-linux-musl | tee shards.sh && \
  mv shards.o shards.sh /tmp

# Build on target platform
FROM alpine:$alpine_version AS target-builder
WORKDIR /tmp
RUN apk add --no-cache \
    zlib-static yaml-static libxml2-dev pcre-dev libevent-static gc-dev \
    libffi-dev g++

ARG crystal_version=1.3.2
COPY --from=builder /tmp/shards.o /tmp/shards.sh .
RUN sh -ex shards.sh
COPY --from=builder /tmp/crystal-${crystal_version} .
RUN /tmp/crystal-${crystal_version}/crystal.sh

# start from a clean image
FROM alpine:$alpine_version

# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static gc-dev git

# copy the binaries + stdlib + libgc from the build stage
COPY --from=target-builder /tmp/crystal /usr/local/bin/
COPY --from=target-builder /tmp/shards /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal
#COPY --from=builder /usr/local/lib/libgc.a /usr/local/lib/
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
