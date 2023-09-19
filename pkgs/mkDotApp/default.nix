{ lib
, runCommand
, buildPackages
, writeScript
, libfaketime
, e2fsprogs
, fakeroot
, squashfsTools
, busybox
}:

{ name
, entrypoint
, paths
# TODO: `cd` into `additionalContent` when present, and add everything from it as-is to the root
#       add its closure, but don't add `additionalContent` itself to the image...
#, additionalContent
}:

# TODO: attach metadata in /.metadata

let
  runner = writeScript "${name}-runner" ''
    #!${busybox}/bin/sh
    printf ":: ${name} launching at: "
    ${busybox}/bin/busybox date +%H:%M:%S.%3N

    # Provide a minimally sufficient environment
    # This helps the actual entrypoint which should provide any additional environment.
    export PATH="${busybox}/bin"

    exec "${entrypoint}" "$@"
  '';
in
runCommand name {
  inherit name;
  blockSize = 1024 * 1024;
  nativeBuildInputs = [
    squashfsTools
    libfaketime
    e2fsprogs.bin
    fakeroot
  ];
  closureInfo = buildPackages.closureInfo { rootPaths = paths ++ [ runner ]; };
  compression = "xz";
  compressionParams = "-Xdict-size 100%";
} /*''
  _mksquashfs() {
    mksquashfs \
    "$@" \
    -b "$blockSize" \
    -comp "$compression" $compressionParams \
    -no-hardlinks -keep-as-directory -all-root \
    -processors $NIX_BUILD_CORES \
    -no-recovery
  }

  mkdir -p $out
  tar c --files-from="$closureInfo/store-paths" | \
    _mksquashfs - "$out/$name.app" -tar -tarstyle

  (
  mkdir -p fs
  cd fs

  # The runner
  ln -s ${runner} .entrypoint

  # Required by POSIX
  mkdir bin
  ln -s ${busybox}/bin/sh bin/sh

  mkdir dev proc sys mnt var tmp

  # Activates dotglob, ignoring . and ..
  # This means hidden files are added too
  GLOBIGNORE=".:.."
  _mksquashfs * "$out/$name.app"
  )
''*/
# Temporarily use an ext4 container for testing on RG35XX vendor kernel...
''
  img="$out/$name.app"
  mkdir -p $out

  (
  # Activates dotglob, ignoring . and ..
  # This means hidden files are added too
  GLOBIGNORE=".:.."
  shopt -u dotglob

  mkdir -p fs
  cd fs

  # Copy closure
  mkdir -p ./nix/store/
  xargs -I % cp -a --reflink=auto % -t ./nix/store/ < $closureInfo/store-paths

  # The runner
  ln -s ${runner} .entrypoint

  # Required by POSIX
  mkdir bin
  ln -s ${busybox}/bin/sh bin/sh

  mkdir dev proc sys mnt var tmp

  # Make a crude approximation of the size of the target image.
  # If the script starts failing, increase the fudge factors here.
  numInodes=$(find ./ | wc -l)
  numDataBlocks=$(du -s -c -B 4096 --apparent-size ./ | tail -1 | awk '{ print int($1 * 1.10) }')
  bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
  echo "Creating an EXT4 image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

  truncate -s $bytes $img

  faketime -f "1970-01-01 00:00:01" fakeroot mkfs.ext4 -L "$name.app" -U "44444444-4444-4444-8888-101010101010" -d ./ $img
  )
''
