{ lib
, pkgs
, callPackage
, targetPkgs
, libc
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
  , lib
  , runCommandInFHSEnv
  , file
  , binutils-unwrapped
  , bintools-unwrapped
  }:

  { name
  , buildCommands
  , ...
  }@args:

  runCommandInFHSEnv name (args // {
    failOnStore = args.failOnStore or 1;
    nativeBuildInputs = [
      stdenv.cc.cc
      binutils-unwrapped
      bintools-unwrapped
      file
    ] ++ lib.optional (args ? nativeBuildInputs) args.nativeBuildInputs;
  }) ''
    is-dynamic() {
      file "$1" | grep 'dynamically linked' > /dev/null
    }
    fhs-interpreter() {
      echo "/$(patchelf --print-interpreter "$1" | cut -d '/' -f5-)"
    }

    export CC; CC=${stdenv.cc.targetPrefix}gcc

    export CFLAGS
    CFLAGS+=(
      ${lib.optionalString (libc != null) ''
      ''}
      $(cat ${stdenv.cc}/nix-support/cc-ldflags)
    )
    export LDFLAGS
    LDFLAGS+=(
      ${lib.optionalString (libc != null) ''
        "-B${libc}/lib"
      ''}
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

    for bin in $out/{usr,}/{s,}bin/*; do
      # Only "fix" dynamic binaries
      if ! [ -L "$bin" ] && is-dynamic "$bin"; then
        # This needs to be done in two steps so the `--remove-rpath` doesn't leave inactive bogus non-rpath entries with nix store path refs.
        (PS4=" $ "; set -x
        patchelf --set-rpath "" "$bin"
        patchelf --remove-rpath --set-interpreter "$(fhs-interpreter "$bin")" "$bin"
        )
      fi
    done
    for lib in $out/{usr,}/lib/*; do
      # Only "fix" dynamic libraries
      if ! [ -L "$lib" ] && is-dynamic "$lib"; then
        # This needs to be done in two steps so the `--remove-rpath` doesn't leave inactive bogus non-rpath entries with nix store path refs.
        (PS4=" $ "; set -x
        patchelf --set-rpath "" "$lib"
        patchelf --remove-rpath "$lib"
        )
      fi
    done

    echo ""
    echo ":: Looking for stray store paths ($NIX_STORE)"
    bogus=()
    for bin in $out/{usr,}/{s,}bin/* $out/{usr,}/lib/*; do
      # Let's not list symlinks
      if ! [ -L "$bin" ]; then
        if (${stdenv.cc.targetPrefix}strings "$bin" | sort -u | grep "$NIX_STORE")>/dev/null; then
          bogus+=("$bin")
        fi
      fi
    done
    if [[ "$bogus" != "" ]]; then
      if [[ "$failOnStore" == 1 ]]; then
        echo "   FATAL: store path references found in:"
      else
        echo "   WARNING: store path references found in:"
      fi
      for bin in "''${bogus[@]}"; do
        echo "-> $bin"
        ${stdenv.cc.targetPrefix}strings "$bin" | sort -u | grep "$NIX_STORE"
      done

      echo ""
      if [[ "$failOnStore" == 1 ]]; then
        exit 1
      fi
    else
      echo "   Nothing found!"
      echo ""
    fi
  ''

) {
  inherit
    runCommandInFHSEnv
  ;
}
