{ stdenv
, fetchurl
, FHSBuilder

, buildPackages
}:

let
  version = "2.28";
in

(FHSBuilder.override { libc = null; }) {
  # Vendor uses 2.28
  name = "glibc-${version}";
  inherit version;

  src = fetchurl {
    url = "mirror://gnu/glibc/glibc-${version}.tar.xz";
    sha256 = "sha256-sZAAUa+tdvek9z5xQT30gm3OCF743beFqUW2bX1RMII=";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    buildPackages.bison
  ];

  buildCommands = ''
    configureFlags=(
      # Reminder: this targets FHS
      --prefix "/usr"

      # Cross
      --build=${stdenv.buildPlatform.config}
      --host=${stdenv.hostPlatform.config}

      -C
      --disable-profile
      --enable-add-ons
      --enable-bind-now
      --enable-stackguard-randomization
      --sysconfdir=/etc
      libc_cv_as_needed=no
    )
    CFLAGS+=(
      "-Os"
      # Make new warnings not error out
      "-Wno-error=array-bounds"
      "-Wno-error=builtin-declaration-mismatch"
      "-Wno-error=missing-attributes"
      "-Wno-error=stringop-truncation"
      "-Wno-error=zero-length-bounds"
    )
    makeFlags=(
      -j$NIX_BUILD_CORES
      "BASH=/bin/bash"
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
      "CC=$CC"
      "CFLAGS=''${CFLAGS[*]}"
      "LDFLAGS=''${LDFLAGS[*]}"
      "V=1"
    )

    tar xf "$src"
    cd glibc-*

    echo ":: Patching..."

    # Needed for glibc to build with the gnumake 3.82
    # http://comments.gmane.org/gmane.linux.lfs.support/31227
    sed -i 's/ot \$/ot:\n\ttouch $@\n$/' manual/Makefile

    sed -i s/-lgcc_eh//g "Makeconfig"
    cat > config.cache << "EOF"
    libc_cv_forced_unwind=yes
    libc_cv_c_cleanup=yes
    libc_cv_gnu89_inline=yes
    EOF

    SOURCE_ROOT="$PWD"
    mkdir ../build
    cd ../build

    echo ":: Configuring"
    "$SOURCE_ROOT"/configure ''${configureFlags[@]}


    echo ":: Building"
    make "''${makeFlags[@]}"
    make "''${makeFlags[@]}" install install_root="$out"
  '';

  failOnStore = false;
}
