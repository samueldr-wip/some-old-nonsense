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
      --prefix "$out"
      --sysconfdir=/etc

      # Cross
      --build=${stdenv.buildPlatform.config}
      --host=${stdenv.hostPlatform.config}

      -C
      --disable-profile
      --enable-add-ons
      --enable-bind-now
      --enable-stackguard-randomization
      --sysconfdir=/etc
      --enable-kernel=3.2.0
      libc_cv_as_needed=no
    )
    CFLAGS+=(
      "-Os"
      "-Wno-error=array-bounds"
      # Make new warnings not error out

      # GCC 10
      "-Wno-error=builtin-declaration-mismatch"
      "-Wno-error=missing-attributes"
      "-Wno-error=stringop-truncation"
      "-Wno-error=zero-length-bounds"

      # GCC 4.9
      "-Wno-error=maybe-uninitialized"
    )
    makeFlags=(
      -j$NIX_BUILD_CORES
      "BASH=/bin/bash"
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
      "CC=$CC"
      "CFLAGS=''${CFLAGS[*]}"
      "LDFLAGS=''${LDFLAGS[*]}"
      "V=1"
      "BUILD_LDFLAGS=-Wl,-rpath,${stdenv.cc.libc}/lib"
    )

    tar xf "$src"
    cd glibc-*

    echo ":: Patching..."

    # Needed for glibc to build with the gnumake 3.82
    # http://comments.gmane.org/gmane.linux.lfs.support/31227
    sed -i 's/ot \$/ot:\n\ttouch $@\n$/' manual/Makefile

    # nscd needs libgcc, and we don't want it dynamically linked
    # because we don't want it to depend on bootstrap-tools libs.
    echo "LDFLAGS-nscd += -static-libgcc" >> nscd/Makefile

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
    make "''${makeFlags[@]}" install sysconfdir=$out/etc # install_root="$out"

    #echo ":: Amending"
    #(
    #  cd $out;
    #  # Not needed
    #  # ref: https://github.com/buildroot/buildroot/blob/da7b674d91e541fdde64cff9181d328562720026/package/glibc/glibc.mk#L160-L163
    #  # Causes issues with absolute paths to the wrong libraries (since prefix is /).
    #  rm usr/lib/libc.so
    #)
  '';

  failOnStore = false;
}
