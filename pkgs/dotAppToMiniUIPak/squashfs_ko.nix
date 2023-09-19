# XXX: This assumes (true for now) that this is targeting
#      only the miyoo mini (true since MiniUI does.)
{ stdenv, linux, fetchurl, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "squashfs.ko";
  src = builtins.fetchGit /Users/samuel/tmp/linux/anbernic-rg35xx;
  ##src = fetchFromGitHub {
  ##  owner = "linux-chenxing";
  ##  repo = "linux-ssc325";
  ##  rev = "979122be45d470e959c2245c996fa93dea10069b"; # takoyaki_dls00v050
  ##  sha256 = "sha256-BvY/fuk4ltZa1mP5XLZjBZWxESNfI31S6SPNtZ5tMrc=";
  ##};

  buildInputs = linux.buildInputs;
  nativeBuildInputs = linux.nativeBuildInputs;
  depsBuildBuild = linux.depsBuildBuild;
  makeFlags = linux.makeFlags;

  patches = [
  ];

  buildPhase = ''
    for f in scripts/dtc/dtc-lexer.l scripts/dtc/dtc-lexer.lex.c_shipped; do
      substituteInPlace "$f" --replace \
        "YYLTYPE yylloc;" "extern YYLTYPE yylloc;"
    done

    # Wrapper around make for readability
    _make() {
      (set -x
      make -j$NIX_BUILD_CORES $makeFlags "''${makeFlagsArray[@]}" "$@"
      )
    }

    # defconfig of the community kernel
    # Hopefully close enough
    _make rg35xx_atm7039_defconfig

    # Config options required to:
    #  (1) build squashfs.ko
    cat >> .config <<EOF
    CONFIG_SQUASHFS=m
    EOF

    # Refresh .config
    _make oldconfig

    # Prepare for build
    _make prepare
    _make scripts
    ${""
    # XXX we may need to generate this, finally :/
    #   WARNING: Symbol version dump /build/source/Module.symvers
    #            is missing; modules will have no dependencies and modversions.
    # https://glandium.org/blog/?p=2664
    # https://github.com/glandium/extract-symvers/blob/master/extract-symvers.py
    }
    cp -v ${./Module.symvers} ./Module.symvers
    _make modules_prepare
    _make SUBDIRS=scripts/mod

    # Then build the module
    _make SUBDIRS=fs/squashfs modules
  '';

  installPhase = ''
    (set -x
    _make INSTALL_PATH='$(out)' INSTALL_MOD_PATH='$(out)' \
      SUBDIRS=fs/squashfs modules_install
    mkdir -p $out
    cp .config $out/config
    )
  '';
}
