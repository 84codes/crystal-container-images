ARG base_image=fedora
ARG base_image_tag=42

# Copy the statically compiled compiler from this image
FROM 84codes/crystal:latest-alpine AS alpine

FROM $base_image:$base_image_tag AS builder
# add dependencies required for building crystal from source
RUN dnf install -y --nodocs --repo=fedora,updates \
        git gcc gcc-c++ make gc-devel llvm-devel \
        pcre2-devel libyaml-devel libffi-devel \
        rpm-build rpmdevtools && \
    dnf clean all

# Use static compiler to compile crystal
COPY --from=alpine /usr/bin/shards /usr/bin/
COPY --from=alpine /usr/bin/crystal /usr/bin/
COPY --from=alpine /usr/share/crystal /usr/share/crystal

# Setup RPM build environment
RUN rpmdev-setuptree

# use rpmbuild to build RPM package
WORKDIR /root/rpmbuild
COPY crystal.spec /root/rpmbuild/SPECS/

ARG crystal_version=1.21.0
ARG shards_version=0.20.0
ARG pkg_revision=1

# Download sources
ARG crystal_src_url=https://github.com/crystal-lang/crystal/archive/${crystal_version}.tar.gz
ADD ${crystal_src_url} /root/rpmbuild/SOURCES/crystal.tar.gz
ADD https://github.com/crystal-lang/shards/archive/refs/tags/v${shards_version}.tar.gz /root/rpmbuild/SOURCES/shards.tar.gz

# Build the RPM package
RUN rpmbuild -bb SPECS/crystal.spec \
    --define "crystal_version $crystal_version" \
    --define "shards_version $shards_version" \
    --define "pkg_revision $pkg_revision"

# put .rpm file in a scratch image for exporting
FROM scratch AS pkgs
COPY --from=builder /root/rpmbuild/RPMS/*/*.rpm .

# start from a clean image
FROM $base_image:$base_image_tag
COPY --from=builder /root/rpmbuild/RPMS/*/*.rpm .
RUN dnf install -y --nodocs --repo=fedora,updates git curl make ./*.rpm && dnf clean all && rm ./*.rpm
# set the default cmd, example usage: docker run --rm 84codes/crystal eval 'puts "hello world"'
ENTRYPOINT ["/usr/bin/crystal"]
