ARG base_image=ubuntu
ARG codename=focal
ARG crystal_version=1.9.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-alpine AS alpine

# link on target platform
FROM $base_image:$codename AS target-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git gcc g++ make autoconf automake libtool
# build libgc
WORKDIR /tmp/libgc
ARG gc_version=8.2.8
RUN git clone --depth=1 --single-branch --branch=v${gc_version} https://github.com/ivmai/bdwgc.git . && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -fPIE -O3" && \
  make install
COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal
COPY --from=alpine /usr/share/doc/crystal /usr/share/doc/crystal
COPY --from=alpine /usr/share/man/man1/crystal.1.gz /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man1/shards.1.gz /usr/share/man/man1/
COPY --from=alpine /usr/share/man/man5/shard.yml.5.gz /usr/share/man/man5/

# build deb package
FROM --platform=$BUILDPLATFORM debian:11 AS pkg-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y ruby binutils \
    && gem install --no-document fpm
WORKDIR /tmp/pkg
# copy the binaries + stdlib + libgc from the build stages
COPY --from=target-builder /usr/lib/libgc.a pkg/usr/lib/crystal/
COPY --from=target-builder /usr/bin/shards pkg/usr/bin/
COPY --from=target-builder /usr/bin/crystal pkg/usr/bin/
COPY --from=target-builder /usr/share/crystal pkg/usr/share/crystal
COPY --from=target-builder /usr/share/doc/crystal pkg/usr/share/doc/crystal
COPY --from=target-builder /usr/share/man/man1/crystal.1.gz pkg/usr/share/man/man1/
COPY --from=target-builder /usr/share/man/man1/shards.1.gz pkg/usr/share/man/man1/
COPY --from=target-builder /usr/share/man/man5/shard.yml.5.gz pkg/usr/share/man/man5/

ARG pkg_revision=1
ARG TARGETARCH
RUN fpm -s dir -t deb -n crystal -v $(cat pkg/usr/share/crystal/src/VERSION) --iteration ${pkg_revision} -a ${TARGETARCH} \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends pkg-config --depends libevent-dev \
  --depends libpcre2-dev \
  --depends libz-dev \
  --deb-recommends libssl-dev --deb-recommends libxml2-dev \
  --deb-recommends libgmp-dev --deb-recommends libyaml-dev \
  --deb-recommends git \
  --license "Apache 2.0" --chdir pkg .

# put .deb file in a scratch image for exporting
FROM scratch AS pkgs
COPY --from=pkg-builder /tmp/pkg/*.deb .

# start from a clean image
FROM $base_image:$codename
# add dependencies commonly required for building crystal applications
ARG DEBIAN_FRONTEND=noninteractive
COPY --from=pkg-builder /tmp/pkg/*.deb .
RUN apt-get update && \
    apt-get install -y curl gnupg make ./*.deb && \
    rm -rf /var/lib/apt/lists/* ./*.deb
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
