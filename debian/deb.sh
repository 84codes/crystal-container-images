#!/bin/sh
set -eu

pkg_version=$(crystal --version | awk 'NR == 1 {print $2}')
pkg_revision=${1:-1}
architecture=$(dpkg --print-architecture)

mkdir debroot
cd debroot

mkdir -p usr/bin usr/lib usr/share/crystal usr/share/doc usr/share/man/man1  usr/share/man/man5
cp -r /usr/share/crystal/src usr/share/crystal/src
cp /usr/bin/crystal /usr/bin/shards usr/bin/
cp /usr/lib/libgc.a usr/lib
# docs
cp -r /usr/share/doc/crystal usr/share/doc/crystal
mv usr/share/doc/crystal/CHANGELOG.md usr/share/doc/crystal/changelog
gzip -9 -n usr/share/doc/crystal/changelog
cp /usr/share/man/man1/crystal.1 usr/share/man/man1/
cp /usr/share/man/man1/shards.1 usr/share/man/man1/
cp /usr/share/man/man5/shard.yml.5 usr/share/man/man5/
gzip -9 -n usr/share/man/man1/* usr/share/man/man5/*

cat > usr/share/doc/crystal/copyright << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Crystal
Upstream-Contact: contact@84codes.com
Source: https://github.com/crystal-lang/crystal
Files: *
Copyright: 2022, Manas Technology Solutions
License: Apache-2.0
EOF

mkdir DEBIAN
find . -type f -not -path "./DEBIAN/*" -print0 | xargs -0 md5sum > DEBIAN/md5sums

cat > DEBIAN/control << EOF
Package: crystal
Version: $pkg_version-$pkg_revision
Architecture: $architecture
Homepage: https://crystal-lang.org
Maintainer: 84codes <contact@84codes.com>
Section: devel
Priority: optional
Installed-Size: $(du -ks usr | cut -f1)
Depends: gcc, pkg-config, libpcre3-dev, libevent-dev
Recommends: libssl-dev, libz-dev, libxml2-dev, libgmp-dev, libyaml-dev
Suggests: git
Description: a general-purpose, object-oriented programming language.
 With syntax inspired by Ruby, it is a compiled language with
 static type-checking, serving both, humans and computers.
EOF

cd ..

debname=crystal_${pkg_version}-${pkg_revision}_${architecture}.deb
echo 2.0 > debian-binary
tar c --directory debroot/DEBIAN . | gzip -9 > control.tar.gz
tar c --directory debroot --exclude=./DEBIAN . | gzip -9 > data.tar.gz
ar rc "$debname" debian-binary control.tar.gz data.tar.gz
