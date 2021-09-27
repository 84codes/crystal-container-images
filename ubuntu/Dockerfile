ARG os_version=20.04

# Compile a static binary of the crystal compile and copy it to a clean ubuntu image
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
  mkdir /usr/local/share/crystal && \
  cp -a src /usr/local/share/crystal/ && \
  cd .. && rm -r *
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  make bin/shards static=1 && \
  cp bin/shards /usr/local/bin/ && \
  cd .. && rm -r *

FROM ubuntu:$os_version
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y build-essential pkg-config libpcre3-dev libevent-dev libgc-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev ca-certificates && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal

ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src
