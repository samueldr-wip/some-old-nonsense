{ lib
, pkgs
, callPackage
, runCommandNoCC
, writeScript
, writeText
, debug ? false
}:

let
  inherit (lib) optionalString;
in

{ app }:

let
  # NOTE: this launcher script has to rely on an ambiant busybox.
  launcher = writeScript "${app.name}-launch.sh" ''
    #!/bin/sh

    _blank() {
      echo ""
      echo ""
      echo ""
      # TODO: blanking :/
    }

    _say() {
      echo ":: $@"
      # TODO: say
      # say "$@"
    }

    ${optionalString debug "set -x"}

    # Directory in which the .app archive is found
    containing_dir=$(dirname "$0")
    name="${app.name}"
    app="$name.app"
    mountpoint="/var/dot-app/$app"

    printf ":: $app launch at: "
    date +%H:%M:%S.%3N

    _blank
    _say "Preparing $app..."

    mkdir -p "$mountpoint"
    mount -t ext4 -o loop,ro "$containing_dir/$app" "$mountpoint"
    for d in dev proc sys tmp var mnt mnt/sdcard; do
      mount -o bind "/$d" "$mountpoint/$d"
    done

    _blank
    _say "Launching $app..."
    printf "   at: "
    date +%H:%M:%S.%3N

    export USERDATA_PATH="/mnt/sdcard/_userdata/"
    mkdir -p $USERDATA_PATH

    # Launch with a neutered environment.
    # It's assumed we don't want any of the vendor things leaking in.
    # XXX provide expected "platform-specific" environment!
    env -i SDL_NOMOUSE=1 "HOME=$USERDATA_PATH" $(which chroot) "$mountpoint" /.entrypoint "$@"

    _blank
    _say "Cleaning-up $app..."
    printf "   at: "
    date +%H:%M:%S.%3N

    # Cleanup after execution
    # NOTE: there is no handling for any child processes.
    for d in dev proc sys tmp var mnt/sdcard mnt; do
      umount -f "$mountpoint/$d"
    done
    umount -df "$mountpoint"
    rmdir --ignore-fail-on-non-empty -p "$mountpoint"

    printf ":: Finished at: "
    date +%H:%M:%S.%3N
  '';

  m3u = writeText "launch.m3u" ''
    launch.sh
  '';
in
runCommandNoCC "${app.name}-pak" {
  inherit app;
  inherit (app) name;
} ''
  dir="$out/$name.pak"
  mkdir -vp "$dir"
  cp -v "$app/$name.app" "$dir"
  cp -v "${launcher}" "$dir"/launch.sh
  cp -v "${m3u}" "$dir/$name.pak.m3u"
''
