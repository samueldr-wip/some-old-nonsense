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

in
FHSBuilder {
  name = "hello";

  outputs = [ "out" ];

  buildCommands = ''
    CFLAGS+=(
      #"-Os"
    )

    "$(type -p $CC)" "''${CFLAGS[@]}" "''${LDFLAGS[@]}" -s ${./hello.c} -o hello
    mkdir -p $out/bin
    mv hello $out/bin/hello
  '';
}

