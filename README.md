# Crystal container images and DEB/RPM packages

Multi-architecture (amd64 and arm64) container image and DEB/RPM package builder for the [Crystal compiler](https://crystal-lang.org/). The images are built daily using [GitHub actions](/.github/workflows/docker.yml).

The container images are published at https://hub.docker.com/r/84codes/crystal and the packages at https://packagecloud.io/84codes/crystal

## Usage

Use these images when you want to build your Crystal app, (pro tip: always use a multi stage approach).

```Dockerfile
FROM 84codes/crystal:latest-ubuntu-22.04 AS builder
WORKDIR /usr/src/app
# Copying and install dependencies
COPY shard.yml shard.lock .
RUN shards install --production
# Copying the rest of the code
COPY src src
# Build binaries
RUN shards build --release --no-debug

# start from a clean ubuntu image
FROM ubuntu:22.04
# install required dependencies
RUN apt-get update && \
    apt-get install -y libssl3 libevent-2.1-7 && \
    apt-get clean && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*
# copy the compiled binary from the build stage
COPY --from=builder /usr/src/app/bin/* /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/myapp"]
```

Smallest images are achieved with static compiled binaries added to a scratch image:

```Dockerfile
# Compile in a build stage
FROM 84codes/crystal:latest-alpine as builder
WORKDIR /tmp
# Copying and install dependencies
COPY shard.yml shard.lock ./
RUN shards install --production
# Copy the rest of the code
COPY src/ src/
# Build a static binary
RUN shards build --release --production --static --no-debug

# The scratch image is completely empty
FROM scratch
# Don't run as root
USER 2:2
# Copy only the binary from the build stage
COPY --from=builder /tmp/bin/* /
# Install a CA store, only needed if the application verifies TLS peers (eg. talk to a https server)
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/
# Set default entrypoint
ENTRYPOINT ["/myapp"]
```

## Supported OSes and versions

We keep up with new releases of Alpine, Ubuntu, Debian and Fedora.

- Alpine latest
- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04
- Debian 10
- Debian 11
- Debian 12
- Fedora 39
- Fedora 40

## Supported Crystal version(s)

We keep up with the releases of offical crystal version releases.

## DEB/RPM packages

DEB and RPM packages are built both for amd64 and arm64, and published at https://packagecloud.io/84codes/crystal.

For best performance use dynamically built packages, they link to the distribution's libraries (there for only a few current versions are supported). For other distributions and versions, use the statically compiled binaries. 

### Install

#### Dynamically linked binaries for recent and current Ubuntu/Debian versions

```sh
curl -fsSL https://packagecloud.io/84codes/crystal/gpgkey | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/84codes_crystal.gpg
. /etc/os-release
echo "deb https://packagecloud.io/84codes/crystal/$ID $VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/84codes_crystal.list
apt-get update
apt-get install crystal
```

#### Dynamically linked binaries for recent and current Fedora versions

```sh
sudo tee /etc/yum.repos.d/84codes_crystal.repo << 'EOF'
[84codes_crystal]
name=84codes_crystal
baseurl=https://packagecloud.io/84codes/crystal/fedora/$releasever/$basearch
gpgkey=https://packagecloud.io/84codes/crystal/gpgkey
repo_gpgcheck=1
gpgcheck=0
EOF
sudo dnf install crystal
```

#### Any Deb based distributions

```sh
curl -fsSL https://packagecloud.io/84codes/crystal/gpgkey | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/84codes_crystal.gpg
echo "deb https://packagecloud.io/84codes/crystal/any any main" | sudo tee /etc/apt/sources.list.d/84codes_crystal.list
apt-get update
apt-get install crystal
```

#### Any RPM based distributions

```sh
sudo tee /etc/yum.repos.d/84codes_crystal.repo << 'EOF'
[84codes_crystal]
name=84codes_crystal
baseurl=https://packagecloud.io/84codes/crystal/rpm_any/rpm_any/$basearch
gpgkey=https://packagecloud.io/84codes/crystal/gpgkey
repo_gpgcheck=1
gpgcheck=0
EOF
sudo dnf install crystal
```

The static packages are built using the binaries from the alpine container and packaged up using [`fpm`](https://fpm.readthedocs.io/en/latest/index.html).

The alpine image is built (multi-arch using buildx+qemu), then in the pkgs dockerfile the files from the alpine container are packaged up and copied to a scratch image, from which the packages are exported and then uploaded to packagecloud.

For details please see:

* [The GitHub workflow](.github/workflows/ci.yml)
* [Alpine dockerfile](alpine/Dockerfile)
* [Pkgs dockerfile](pkgs/Dockerfile)
