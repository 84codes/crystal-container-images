ARG alpine_version=latest

FROM alpine:$alpine_version AS builder
WORKDIR /tmp

# add dependencies required for building crystal from source
RUN apk add --update --no-cache crystal shards musl-dev llvm11-dev llvm11-static libxml2-dev zlib-static yaml-static g++ make wget

ARG crystal_version=1.1.1
ARG shards_version=0.15.0

# download the crystal source, compile and install it
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

# download the shards source, compile and install it
RUN wget https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz && \
  tar zxf v${shards_version}.tar.gz && \
  cd shards-${shards_version} && \
  make bin/shards static=1 && \
  cp bin/shards /usr/local/bin/ && \
  strip /usr/local/bin/shards && \
  cd .. && rm -r *

# start from a clean image
FROM alpine:$alpine_version

# add dependencies commonly required for building crystal applications
RUN apk add --update --no-cache musl-dev gcc gc-dev pcre-dev libevent-dev libevent-static openssl-dev openssl-libs-static libxml2-dev zlib-dev zlib-static git

# copy the binaries + stdlib from the build stage
COPY --from=builder /usr/local/bin/crystal /usr/local/bin/
COPY --from=builder /usr/local/bin/shards /usr/local/bin/
COPY --from=builder /usr/local/share/crystal /usr/local/share/crystal
ENV CRYSTAL_PATH=lib:/usr/local/share/crystal/src

# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/local/bin/crystal"]
