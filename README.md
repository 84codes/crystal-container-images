# Crystal container images

Multi-architecture (amd64 and arm64, more can be added) container/docker image builder for the [Crystal compiler](https://crystal-lang.org/). The images are built daily using [GitHub actions](/.github/workflows/docker.yml).

The images are published at https://hub.docker.com/r/84codes/crystal

## Usage

Use these images when you want to build your Crystal app, (pro tip: always use a multi stage approach).

Smallest images are achieved with static compiled binaries added to a scratch image:

```Dockerfile
# Compile in a build stage
FROM 84codes/crystal:1.1.1-alpine-latest as builder
WORKDIR /tmp

# Copying and install dependencies
COPY shard.yml shard.lock ./
RUN shards install --production

# Copy the rest of the code
COPY src/ src/

# Build a static binary
RUN shards build --release --production --static

# Strip debug symbols for even smaller binary/image, but it will make printed stacktraces look empty
RUN strip bin/*

# The scratch image is completely empty
FROM scratch

# Don't run as root
USER 2:2

# Copy only the binary from the build stage
COPY --from=builder /tmp/bin/* /

# Install a CA store, only needed if the application verifies TLS peers (eg. talk to a https server)
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/

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

# Strip if want a smaller image, but stacktraces won't be useful
RUN strip bin/*

# start from a clean ubuntu image
FROM ubuntu:18.04

# install required dependencies
RUN apt-get update && \
    apt-get install -y libssl1.1 libevent-2.1-* && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*

# copy the compiled binary from the build stage
COPY --from=builder /tmp/bin/* /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/myapp"]
```

## Supported OSes and versions

- Alpine latest
- Ubuntu 18.04
- Ubuntu 20.04
- Debian Buster
- Debian Bullseye
- others on request

## Supported Crystal version(s)

More versions are easily added, but currently images are build for these Crystal versions:

- 1.1.1
