ARG alpine_version=latest

FROM alpine:latest AS builder
RUN apk add --update --no-cache crystal shards musl-dev llvm11-dev llvm11-static libxml2-dev zlib-static yaml-static g++ make wget

ARG crystal_version=1.1.1
ARG shards_version=0.15.0

WORKDIR /tmp

RUN wget https://github.com/crystal-lang/crystal/archive/refs/tags/${crystal_version}.tar.gz && \
  tar zxf ${crystal_version}.tar.gz && \
  cd crystal-${crystal_version} && \
  make crystal static=1 && \
  rm src/llvm/ext/llvm_ext.o && \
  cp .build/crystal /usr/local/bin/ && \
  strip /usr/local/bin/crystal && \
  mkdir /usr/local/share/crystal && \
  cp -a src /usr/local/share/crystal/ && \
  cd .. && rm -r *
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  make bin/shards static=1 && \
  cp bin/shards /usr/local/bin/ && \
  strip /usr/local/bin/shards && \
  cd .. && rm -r *

FROM alpine:$alpine_version
COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal
RUN apk add --update --no-cache musl-dev gcc gc-dev pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src
