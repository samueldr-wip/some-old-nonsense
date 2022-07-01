{ lib
, callPackage
, targetPkgs
}:

let
  fhsWrapper =
    callPackage (
      { buildFHSUserEnv }:

      old: args: buildFHSUserEnv {
        name = "wrapper";
        runScript = "$@";
      } // args
    ) { }
  ;

  runInFHSEnv =
    callPackage (
      { lib }:

      drv: args: lib.overrideDerivation drv (old: {
        builder = "${fhsWrapper old args}/bin/wrapper";
        args = [old.builder] ++ old.args;
      })
    ) { }
  ;

  runCommandInFHSEnv =
    callPackage (
      { runInFHSEnv, runCommandNoCC }:
      name: env: script:
      runInFHSEnv (runCommandNoCC name env script)
      { targetPkgs = _: []; }
    ) { inherit runInFHSEnv; }
  ;
in
targetPkgs.callPackage (
  { stdenv
  , runCommandInFHSEnv
  , gcc-unwrapped
  , binutils-unwrapped
  , bintools-unwrapped
  }:

  { name
  , buildCommands
  , ...
  }@args:

  runCommandInFHSEnv name (args // {
    nativeBuildInputs = [
      gcc-unwrapped
      binutils-unwrapped
      bintools-unwrapped
    ] ++ lib.optional (args ? nativeBuildInputs) args.nativeBuildInputs;
  }) ''
    fhs-interpreter() {
      echo "/$(patchelf --print-interpreter "$1" | cut -d '/' -f5-)"
    }

    export CC; CC=${stdenv.cc.targetPrefix}gcc

    export CFLAGS
    CFLAGS+=(
      $(cat ${stdenv.cc}/nix-support/libc-crt1-cflags)
      $(cat ${stdenv.cc}/nix-support/cc-ldflags)
    )
    export LDFLAGS
    LDFLAGS+=(
      $(cat ${stdenv.cc}/nix-support/libc-crt1-cflags)
      $(cat ${stdenv.cc}/nix-support/cc-ldflags)
    )

    export LIBRARY_PATH=/lib

    echo ""
    echo ":: Running buildCommands"
    (PS4=" $ "; set -x
    ${buildCommands}
    )

    echo ""
    echo ":: Un-nixifying build"

    for bin in $out/bin/*; do
      # This needs to be done in two steps so the `--remove-rpath` doesn't leave inactive bogus non-rpath entries with nix store path refs.
      if [ -f "$bin" ]; then
        (PS4=" $ "; set -x
        patchelf --set-rpath "" "$bin"
        patchelf --remove-rpath --set-interpreter "$(fhs-interpreter "$bin")" "$bin"
        )
      fi
    done

    echo ""
    echo ":: Looking for stray store paths ($NIX_STORE)"
    bogus=()
    for bin in $out/bin/*; do
      if ${stdenv.cc.targetPrefix}strings "$bin" | sort -u | grep -q "$NIX_STORE"; then
        bogus+=("$bin")
      fi
    done
    if [[ "$bogus" != "" ]]; then
      echo "   FATAL: store path references found in:"
      for bin in "''${bogus[@]}"; do
        echo "-> $bin\n"
        ${stdenv.cc.targetPrefix}strings "$bin" | sort -u | grep "$NIX_STORE"
      done

      echo ""
      exit 1
    fi
    echo "   Nothing found!"
    echo ""
  ''

) {
  inherit
    runCommandInFHSEnv
  ;
}
