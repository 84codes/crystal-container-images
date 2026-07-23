ARG base_image=debian
ARG codename=trixie

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:latest-alpine AS alpine

FROM $base_image:$codename AS builder
# add dependencies required for building crystal from source
ARG llvm_version=19
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git gcc g++ pkg-config make \
    libpcre2-dev libyaml-dev zlib1g-dev llvm-$llvm_version-dev \
    autoconf automake libtool libffi-dev devscripts debhelper dh-make

COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
WORKDIR /usr/src

# build libgc
ARG gc_version=8.2.8
ADD https://github.com/ivmai/bdwgc/archive/v${gc_version}.tar.gz bdwgc.tar.gz
RUN tar zxf bdwgc.tar.gz && \
    cd bdwgc-${gc_version} && \
    ./autogen.sh && \
    ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
    make -j$(nproc) $(shell dpkg-buildflags --export=cmdline) && \
    make install

# Build crystal
ARG crystal_version=1.21.0
ARG crystal_src_url=https://github.com/crystal-lang/crystal/archive/${crystal_version}.tar.gz
ADD ${crystal_src_url} crystal.tar.gz
RUN tar zxf crystal.tar.gz && \
    cd crystal-${crystal_version} && \
    make release=1 interpreter=1 CRYSTAL_CONFIG_LIBRARY_PATH=/usr/lib/crystal LDFLAGS="$(dpkg-buildflags --get LDFLAGS)" && \
    make install PREFIX=/usr DESTDIR=/tmp/crystal

# Build shards
ARG shards_version=0.20.0
ADD https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz shards.tar.gz
RUN tar zxf shards.tar.gz && \
    cd shards-${shards_version} && \
    make release=1 FLAGS="--link-flags=\"$(dpkg-buildflags --get LDFLAGS)\"" && \
    make install PREFIX=/usr DESTDIR=/tmp/crystal

# Setup package source directory
WORKDIR /tmp/crystal
RUN install -D /usr/lib/libgc.a usr/lib/crystal/libgc.a
COPY debian/ debian/

# Copy debian package files
ARG pkg_revision=1

# Update version and llvm version in control file
RUN deb_version=$(echo "${crystal_version}" | sed 's/^[^0-9]/0~/; s/-/./g') && \
    sed -i "s/\${crystal_version}/${deb_version}/g; s/\${pkg_revision}/${pkg_revision}/g; s/\$(date -R)/$(date -R)/g" debian/changelog && \
    sed -i "s/\$(date +%Y)/$(date +%Y)/g" debian/copyright

# Build the package
RUN debuild -us -uc -b

# put .deb file in a scratch image for exporting
FROM scratch AS pkgs
COPY --from=builder /tmp/crystal/../*.deb .

# start from a clean image
FROM $base_image:$codename
# add dependencies commonly required for building crystal applications
COPY --from=builder /tmp/*.deb .
RUN apt-get update && \
    apt-get install -y curl gnupg ./*.deb && \
    rm -rf /var/lib/apt/lists/* ./*.deb
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
