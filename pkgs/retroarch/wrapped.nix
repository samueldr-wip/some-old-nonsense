{ symlinkJoin
, writeText
, fetchFromGitHub
, retroarch
, cores
, retroarch-assets
}:
let
  libretroCoreInfo = fetchFromGitHub {
    owner = "libretro";
    repo = "libretro-core-info";
    sha256 = "sha256-3nw8jUxBQJxiKlWS6OjTjwUYWKx3r2E7eHmbj4naWrk=";
    rev = "v1.14.0";
  };
  forcedConfig = writeText "retroarch-forced-fragment.cfg" ''
    # Core information is required, or else cores can't be loaded.
    libretro_info_path = "${libretroCoreInfo}"
    core_info_cache_enable = "false"

    # Restart is buggy on some platforms...
    # ... and undesirable UX-wise...
    menu_show_restart_retroarch = "false"

    # Preload assets.
    assets_directory = "${retroarch-assets}"
  '';
in
symlinkJoin {
  name = "retroarch-wrapped";
  paths = cores;
  postBuild = ''
    mkdir -p $out/bin
    cat <<EOF > $out/bin/retroarch
    #!/bin/sh
    exec -a retroarch \
      ${retroarch}/bin/retroarch \
      --verbose \
      --libretro=${placeholder "out"}/lib/retroarch/cores \
      --appendconfig=${forcedConfig} \
      "\$@"
    EOF
    chmod +x $out/bin/retroarch
  '';
}
/*
      --log-file=/mnt/SDCARD/retroarch.log \
*/
#    set -x
#    # XXX fix sound when running on MiniUI as a pak file
#    pkill audioserver
#    pkill keymon
#    sleep 0.3
#    # XXX ^^^^
