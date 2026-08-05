Name:           crystal
Version:        %(echo %{getenv:crystal_version} | tr '-' '.')
Release:        %{getenv:pkg_revision}%{?dist}
Summary:        A general-purpose, object-oriented programming language
License:        Apache-2.0
URL:            https://crystal-lang.org
Packager:       84codes <contact@84codes.com>

%define _enable_debug_packages 0

BuildRequires:  git gcc gcc-c++ make gc-devel llvm-devel
BuildRequires:  pcre2-devel libyaml-devel libffi-devel
BuildRequires:  asciidoctor

Requires:       gcc pkgconfig gc-devel
Requires:       pcre2-devel openssl-devel zlib-devel
Requires:       libyaml-devel libxml2-devel gmp-devel
# Commonly used by shards
Requires:       git make

Source0: crystal.tar.gz
Source1: shards.tar.gz

%description
Crystal is a programming language with the following goals:
- Have a syntax similar to Ruby (but compatibility with it is not a goal)
- Statically type-checked but without having to specify the type of variables or method arguments
- Be able to call C code by writing bindings to it in Crystal
- Have compile-time evaluation and generation of code, to avoid boilerplate code
- Compile to efficient native code

%prep
%setup -q -n crystal-%{getenv:crystal_version} -b 1

%build
# Build Crystal
cd ../crystal-%{getenv:crystal_version}
make release=1 interpreter=1 LDFLAGS="%{build_ldflags}" CRYSTAL_CONFIG_LIBRARY_PATH=%{_libdir}/crystal

# Build Shards
cd ../shards-%{getenv:shards_version}
make release=1 FLAGS="--link-flags=\"%{build_ldflags}\""

%install
# Install Crystal
cd ../crystal-%{getenv:crystal_version}
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

# Install Shards
cd ../shards-%{getenv:shards_version}
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

%files
%license %{_datadir}/licenses/crystal/LICENSE
%{_bindir}/crystal
%{_bindir}/shards
%{_datadir}/crystal
%{_datadir}/zsh/site-functions/_crystal
%{_datadir}/bash-completion/completions/crystal
%{_datadir}/fish/vendor_completions.d/crystal.fish
%{_mandir}/man1/crystal.1.gz
%{_mandir}/man1/shards.1.gz
%{_mandir}/man5/shard.yml.5.gz

%changelog
* Tue Apr 15 2025 84codes <contact@84codes.com> - %{version}-1
- Updated to Crystal %{version}
