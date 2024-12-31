{ stdenv
, lib
, pkg-config

, freetype

# miyoomini, miyoo
, SDL
, glibc

## # XXX RG351...
## , alsa-lib
## , libGL
## , SDL2
## , libdrm
## , mesa
## , udev
## #, librga
}:

stdenv.mkDerivation {
  pname = "retroarch";
  version = "2022-12-18";
  src = builtins.fetchGit {
    url = ../../PROJECTS/RetroArch;
    #ref = "refs/heads/wip/gocfw-miyoo-mini";
    #ref = "refs/remotes/libretro/master";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    #/*
    # miyoo
    SDL
    freetype
    glibc
    #*/

    /*
    # XXX RG351
    libGL
    SDL2
    freetype
    alsa-lib
    libdrm
    mesa
    udev
    #librga
    #*/
  ];

  makeFlags = [
    #/*
    # miyoo
    "-f" "Makefile.miyoomini"
    #*/
    # cannot find crt1.o
    # cannot find crti.o
    "LDFLAGS=-B${lib.getLib glibc}/lib"
  ];

  #/*
  # miyoo
  FREETYPE_CONFIG = "${freetype.dev}/bin/freetype-config";
  SDL_CONFIG = "${SDL.dev}/bin/sdl-config";
  #*/


#/*
  # miyoo
  configurePhase = ''
    runHook preConfigure
    runHook postConfigure
  '';
#*/

/*
    # XXX RG351
  configureFlags = [
    # Features that don't make sense
    "--disable-update_cores"
    "--disable-discord"
    "--disable-ffmpeg"
    "--disable-wayland"
    "--disable-x11"

    # Frameworks and libs that don't apply here
    "--disable-qt"
    "--disable-sdl"
    "--disable-mali_fbdev"
    "--disable-opengl"
    "--disable-opengl1"
    "--disable-vg"
    "--disable-vulkan"
    "--disable-vulkan_display"

    # Basic fraemworks and libs in use
    "--enable-alsa"
    "--enable-egl"
    "--enable-kms"
    "--enable-opengles"
    "--enable-opengles3"
    "--enable-opengles3_2"
    "--enable-freetype"
    "--enable-sdl2"
    "--enable-udev"
    "--enable-zlib"

    # Platform specific options
    #"--enable-odroidgo2"
  ];
#*/

  installPhase = ''
    mkdir -p $out/bin
    cp retroarch $out/bin/
  '';

  enableParallelBuilding = true;

  meta = {
    platforms = lib.platforms.linux;
  };
}
