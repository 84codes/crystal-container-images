ARG base_image=debian
ARG base_image_tag=latest
ARG crystal_version=1.4.1

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:${crystal_version}-pkgs AS pkgs

# Result image
FROM $base_image:$base_image_tag
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y git gcc g++ pkg-config make \
    libpcre3-dev libevent-dev libssl-dev libgmp-dev libyaml-dev libxml2-dev zlib1g-dev && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/cache/debconf/* /var/log/*
COPY --from=pkgs *.deb /tmp/
RUN dpkg -i /tmp/*.deb && rm /tmp/*.deb
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
