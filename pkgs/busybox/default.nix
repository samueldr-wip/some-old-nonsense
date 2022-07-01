{ stdenv
, lib
, FHSBuilder
, buildPackages
, busybox
, gcc-unwrapped
}:

let
  inherit (lib) concatStringsSep;
in
FHSBuilder {
  name = "busybox";

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  outputs = [ "out" "config" ];

  buildCommands = ''
    CFLAGS+=(
      "-L${stdenv.cc.libc}/lib"
      "-L${gcc-unwrapped.lib}/lib"
    )
    LDFLAGS+=(
      "-L${stdenv.cc.libc}/lib"
      "-L${gcc-unwrapped.lib}/lib"
    )
    makeFlags=(
      -j$NIX_BUILD_CORES
      "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
      "CC=$CC"
      "CFLAGS=''${CFLAGS[*]}"
      "LDFLAGS=''${LDFLAGS[*]}"
      "V=1"
    )
    tar xf ${busybox.src}
    cd busybox-*
    make defconfig
    grep -v '${concatStringsSep ''\|'' [
      "^CONFIG_CROSS_COMPILER_PREFIX="
      "^CONFIG_PREFIX="
      "^CONFIG_DPKG"
      "CONFIG_UNLZOP[= ]"
      "CONFIG_LZOPCAT[= ]"
      "^CONFIG_XXD="
      "^CONFIG_W="
      "^CONFIG_UDHCPC6[= ]"
      "^CONFIG_SSL_CLIENT[= ]"
      "^CONFIG_UEVENT[= ]"
    ]}' .config > tmp.config
    mv tmp.config .config
    cat <<EOF >> .config
    CONFIG_CROSS_COMPILER_PREFIX="${stdenv.cc.targetPrefix}"
    CONFIG_PREFIX="$out"
    # CONFIG_DPKG is not set
    # CONFIG_DPKG_DEB is not set
    CONFIG_UNLZOP=y
    CONFIG_LZOPCAT=y
    # CONFIG_XXD is not set
    # CONFIG_W is not set
    # CONFIG_UDHCPC6 is not set
    # CONFIG_SSL_CLIENT is not set
    # CONFIG_UEVENT is not set
    EOF
    #cat .config
    make oldconfig
    make "''${makeFlags[@]}" install
    mkdir -p $out
    cp -v .config $config
  '';
}
