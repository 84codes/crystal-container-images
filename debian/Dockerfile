ARG base_image=debian
ARG base_image_tag=latest
ARG crystal_version=1.4.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine-latest AS alpine

# Build libgc
FROM $base_image:$base_image_tag AS libgc-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y curl gcc g++ make libc-dev autoconf automake libtool
WORKDIR /tmp/libgc
ARG gc_version=8.2.0
RUN curl --retry 5 -sL https://github.com/ivmai/bdwgc/archive/refs/tags/v${gc_version}.tar.gz | \
  tar -zxf- --strip-components=1
RUN ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install

# build debian package
FROM $base_image:$base_image_tag AS deb-builder
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y binutils
COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
COPY --from=alpine /usr/share/doc/crystal /usr/share/doc/crystal
COPY --from=alpine /usr/share/man/man1/crystal.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man1/shards.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man5/shard.yml.5 /usr/share/man/man5/
COPY --from=libgc-builder /usr/lib/libgc.a /usr/lib/
WORKDIR /tmp
COPY deb.sh .
ARG deb_revision=1
RUN sh -eux deb.sh ${deb_revision}

# put .deb file in a scratch image for exporting
FROM scratch AS deb
COPY --from=deb-builder /tmp/*.deb .

# Result image
FROM $base_image:$base_image_tag
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git build-essential pkg-config \
    libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*
COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
COPY --from=alpine /usr/share/doc/crystal /usr/share/doc/crystal
COPY --from=alpine /usr/share/man/man1/crystal.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man1/shards.1 /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man5/shard.yml.5 /usr/share/man/man5/
COPY --from=libgc-builder /usr/lib/libgc.a /usr/lib/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
