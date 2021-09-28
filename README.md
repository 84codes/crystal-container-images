# Crystal container images

Multi architecture (amd64 and arm64 for now) container/docker image builder for the [Crystal compiler](https://crystal-lang.org/). The images are built using [GitHub actions](/.github/workflows/docker.yml).

The images are published at https://hub.docker.com/r/84codes/crystal

## Supported OSes and versions

- Alpine latest
- Ubuntu 18.04
- Ubuntu 20.04
- others on request

## Supported Crystal version(s)

More versions are easily added, but currently images are build for these Crystal versions:

- 1.1.1

## Usage

Use these images when you want to build your Crystal app using a multi layer approach.

Smallest images are achieved with static compiled binaries added to a scratch image:

```Dockerfile
# Compile in a build layer
FROM 84codes/crystal:1.1.1-alpine-latest as builder
WORKDIR /tmp

# Copying and install dependencies
COPY shard.yml shard.lock ./
RUN shards install --production

# Copy the rest of the code
COPY src/ src/

# Build a static binary
RUN shards build --release --production --static

# Strip debug symbols for even smaller binary/image, but it will make stacktraces useless
RUN strip bin/*

# The scratch image is completely empty
FROM scratch

# Don't run as root
USER 2:2

# Copy the binary from the build image
COPY --from=builder /tmp/bin/* /

ENTRYPOINT ["/myapp"]
```

Static compiled binaries are great, but glibc dynamically compiled images can perform better.

```Dockerfile
FROM 84codes/crystal:1.1.1-ubuntu-18.04 AS builder
WORKDIR /tmp

# Copying and install dependencies
COPY shard.yml shard.lock ./
RUN shards install --production

# Copying the rest of the code
COPY ./src ./src

# Build
RUN shards build --production --release
RUN strip bin/*

# start from scratch and only copy the built binary
FROM ubuntu:18.04

# install required dependencies
RUN apt-get update && \
    apt-get install -y libssl1.1 libevent-2.1-* && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

COPY --from=builder /tmp/bin/* /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/myapp"]
```
