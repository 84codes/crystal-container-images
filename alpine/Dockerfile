ARG alpine_version=latest

FROM alpine:$alpine_version AS builder
ARG llvm_version=20
# add dependencies required for building crystal from source
RUN apk add --update --no-cache \
    crystal shards \
    llvm${llvm_version}-dev llvm${llvm_version}-static \
    zlib-static yaml-static pcre2-dev zstd-static libxml2-static pcre2-static \
    libffi-dev git g++ make automake libtool autoconf curl abuild asciidoctor

WORKDIR /usr/src
# Build libgc
ARG gc_version=8.2.8
ADD https://github.com/ivmai/bdwgc/archive/v${gc_version}.tar.gz bdwgc.tar.gz
RUN tar zxf bdwgc.tar.gz && \
    cd bdwgc-${gc_version} && \
    source /usr/share/abuild/default.conf && \
    ./autogen.sh && \
    ./configure --disable-debug --disable-shared --enable-large-config --prefix=/usr && \
    make -j$(nproc) && \
    make install

# Build crystal
ARG crystal_version=1.21.0
ARG crystal_src_url=https://github.com/crystal-lang/crystal/archive/${crystal_version}.tar.gz
ADD ${crystal_src_url} crystal.tar.gz
RUN tar zxf crystal.tar.gz && \
    cd crystal-${crystal_version} && \
    source /usr/share/abuild/default.conf && \
    make release=1 static=1 CRYSTAL_CONFIG_LIBRARY_PATH=/usr/lib/crystal LDFLAGS="$LDFLAGS -s -w" && \
    make install PREFIX=/usr

# Build shards
WORKDIR /usr/src/shards
ARG shards_version=0.20.0
ADD https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz shards.tar.gz
RUN tar zxf shards.tar.gz && \
    cd shards-${shards_version} && \
    source /usr/share/abuild/default.conf && \
    make release=1 static=1 CRYSTAL_CONFIG_LIBRARY_PATH=/usr/lib/crystal FLAGS="--link-flags=\"$LDFLAGS -s -w\"" && \
    make install PREFIX=/usr

# start from a clean image
FROM alpine:$alpine_version
# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc pcre2-dev openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git make yaml-dev libxml2-static gmp-dev xz-static yaml-static pcre2-static
# copy the binaries + stdlib + libgc from the build stage
COPY --from=builder /usr/share/man/man1/crystal.1.gz /usr/share/man/man1/
COPY --from=builder /usr/share/man/man1/shards.1.gz /usr/share/man/man1/
COPY --from=builder /usr/share/man/man5/shard.yml.5.gz /usr/share/man/man5/
COPY --from=builder /usr/share/crystal /usr/share/crystal
COPY --from=builder /usr/bin/crystal /usr/bin/
COPY --from=builder /usr/bin/shards /usr/bin/
COPY --from=builder /usr/lib/libgc.a /usr/lib/crystal/
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
