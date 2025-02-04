# Copy the statically compiled compiler from the alpine image
ARG crystal_version=1.15.1
FROM 84codes/crystal:${crystal_version}-alpine-latest AS alpine

# build deb and rpm packages
FROM debian:11 AS pkg-builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git gcc g++ make libc-dev autoconf automake libtool ruby rpm binutils \
    && gem install fpm
# build libgc
WORKDIR /tmp/libgc
ARG gc_version=8.2.8
RUN git clone --depth=1 --single-branch --branch=v${gc_version} https://github.com/ivmai/bdwgc.git . && \
  ./autogen.sh && \
  ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
  make -j$(nproc) CFLAGS="-DNO_GETCONTEXT -pipe -O3" && \
  make install
# build distribution packages
WORKDIR /tmp/pkg
COPY --from=alpine /usr/bin/shards pkg/usr/bin/
COPY --from=alpine /usr/bin/crystal pkg/usr/bin/
COPY --from=alpine /usr/share/crystal pkg/usr/share/crystal
COPY --from=alpine /usr/share/doc/crystal pkg/usr/share/doc/crystal
COPY --from=alpine /usr/share/man/man1/crystal.1.gz pkg/usr/share/man/man1/
COPY --from=alpine /usr/share/man/man1/shards.1.gz pkg/usr/share/man/man1/
COPY --from=alpine /usr/share/man/man5/shard.yml.5.gz pkg/usr/share/man/man5/
RUN mkdir -p pkg/usr/lib && cp /usr/lib/libgc.a pkg/usr/lib/
ARG crystal_version=1.15.1
ARG pkg_revision=1
RUN fpm -s dir -t deb -n crystal -v ${crystal_version} --iteration ${pkg_revision} -a native \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends libpcre2-dev --depends pkg-config --depends libevent-dev \
  --deb-recommends libssl-dev --deb-recommends libz-dev --deb-recommends libxml2-dev \
  --deb-recommends libgmp-dev --deb-recommends libyaml-dev --deb-recommends git \
  --license "Apache 2.0" --chdir pkg .
RUN fpm -s dir -t rpm -n crystal -v ${crystal_version} --iteration ${pkg_revision} -a native \
  --url https://crystal-lang.org --maintainer "84codes <contact@84codes.com>" \
  --description "a general-purpose, object-oriented programming language" \
  --depends gcc --depends pcre2-devel --depends pkgconfig --depends libevent-devel \
  --depends gmp-devel --depends openssl-devel --depends libxml2-devel \
  --depends libyaml-devel --depends zlib-devel \
  --license "ASL 2.0" --chdir pkg .

# put .deb file in a scratch image for exporting
FROM scratch
COPY --from=pkg-builder /tmp/pkg/*.deb /tmp/pkg/*.rpm .
