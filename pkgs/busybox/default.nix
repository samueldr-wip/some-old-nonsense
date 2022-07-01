{ stdenv
, lib
, FHSBuilder
, buildPackages
, busybox
, gcc-unwrapped
}:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
  ;

  # Minimal way to handle **only** `=y` and "`=n`" configs.

  enabled = [
    "LZOPCAT"
    "UNLZOP"
  ];
  disabled = [
    "BB_ARCH" # for `arch`
    "ASCII"
    "BASE32"
    "BC"
    "BLKDISCARD"
    "CRC32"
    "DPKG"
    "DPKG_DEB"
    "FACTOR"
    "FALLOCATE"
    "FATATTR"
    "FSFREEZE"
    "FSTRIM"
    "HEXEDIT"
    "I2CDETECT"
    "I2CDUMP"
    "I2CGET"
    "I2CSET"
    "I2CTRANSFER"
    "IPNEIGH"
    "LINK"
    "LSSCSI"
    "MIM"
    "NL"
    "NOLOGIN"
    "NPROC"
    "NSENTER"
    "PARTPROBE"
    "PASTE"
    "RESUME"
    "RUN_INIT"
    "SETFATTR"
    "SETPRIV"
    "SHA3SUM"
    "SHRED"
    "SHUF"
    "SSL_CLIENT"
    "SVC"
    "SVOK"
    "TASKSET"
    "TC"
    "TRUNCATE"
    "TS"
    "UBIRENAME"
    "UDHCPC6"
    "UEVENT"
    "UNLINK"
    "UNSHARE"
    "W"
    "XXD"
  ];
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
    grep -v '${concatStringsSep ''\|'' (
        [
          "^CONFIG_CROSS_COMPILER_PREFIX="
          "^CONFIG_PREFIX="
        ]
        ++ (map (name: ''CONFIG_${name}[= ]'') (enabled ++ disabled))
    )}' .config > tmp.config
    mv tmp.config .config
    cat <<EOF >> .config
    CONFIG_CROSS_COMPILER_PREFIX="${stdenv.cc.targetPrefix}"
    CONFIG_PREFIX="$out"
    ${concatMapStringsSep "\n" (name: ''CONFIG_${name}=y'') enabled}
    ${concatMapStringsSep "\n" (name: ''# CONFIG_${name} is not set'') disabled}
    EOF

    # Normalize config
    make oldconfig

    # Build and install
    make "''${makeFlags[@]}" install

    cp -v .config $config
  '';
}
