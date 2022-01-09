ARG alpine_version=latest

FROM alpine:$alpine_version AS builder
WORKDIR /tmp

ARG llvm_version=11
# add dependencies required for building crystal from source
RUN apk add --update --no-cache \
    crystal shards \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static libxml2-dev pcre-dev libevent-static \
    libffi-dev \
    git g++ make automake libtool autoconf wget

ENV CFLAGS="-pipe -O3"

# Build libgc
ARG gc_version=8.2.0
RUN wget https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz && \
  tar zxf v${gc_version}.tar.gz && \
  cd bdwgc-${gc_version} && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config && \
  make -j$(nproc) CFLAGS=-DNO_GETCONTEXT && \
  make install
ENV CRYSTAL_LIBRARY_PATH=/usr/local/lib

# Build crystal
ARG crystal_version=1.3.0
RUN wget https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz && \
  tar zxf ${crystal_version}.tar.gz && \
  cd crystal-${crystal_version} && \
  FLAGS=-Dwithout_playground make crystal static=1 release=1 && \
  rm src/llvm/ext/llvm_ext.o && \
  cp .build/crystal /usr/local/bin/ && \
  strip /usr/local/bin/crystal && \
  mkdir /usr/local/share/crystal && \
  cp -a src /usr/local/share/crystal/
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# Build shards
ARG shards_version=0.16.0
RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  make bin/shards static=1 release=1 && \
  cp bin/shards /usr/local/bin/ && \
  strip /usr/local/bin/shards

# start from a clean image
FROM alpine:$alpine_version

# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git

# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal
COPY --from=builder /usr/local/lib/libgc.a /usr/local/lib/
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
