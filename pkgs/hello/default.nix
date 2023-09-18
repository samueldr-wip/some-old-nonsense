{ stdenv

, meson
, ninja
, pkg-config
, vala

, SDL
, cairo
, glib
}:

stdenv.mkDerivation {
  pname = "games-os-hello";
  version = "2022-11-09";

  src = builtins.fetchGit /Users/samuel/Projects/Shared/wip-stub-ui;

  buildInputs = [
    SDL
    cairo
    glib
  ];

  # XXX platform cargo cults how?
##  NIX_CFLAGS_COMPILE = [
##    "-Os"
##    "-marm"
##    "-mtune=cortex-a7"
##    "-march=armv7ve+simd"
##    "-mfpu=neon-vfpv4"
##    "-mfloat-abi=hard"
##    "-std=gnu11"
##    "-fPIC"
##    "-ffunction-sections"
##    "-fdata-sections"
##    "-Wall"
##  ];
##  NIX_LDFLAGS = [
##    "-s"
##  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
  ];
}
