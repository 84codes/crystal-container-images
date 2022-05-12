ARG base_image=fedora
ARG base_image_tag=latest
ARG crystal_version=1.4.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-pkgs AS pkgs

# Resulting image
FROM $base_image:$base_image_tag
RUN dnf install -y --nodocs \
        gcc make git libevent-devel \
        pcre-devel libxml2-devel libyaml-devel \
        openssl-devel zlib-devel gmp-devel && \
    dnf clean all
COPY --from=pkgs *.rpm /tmp/
RUN rpm -i /tmp/*.rpm && rm /tmp/*.rpm
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
