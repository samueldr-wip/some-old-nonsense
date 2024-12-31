{ stdenv
, SDL
, SDL_image
, SDL_ttf
}:

stdenv.mkDerivation {
  pname = "minui";
  version = "dev";
  src = builtins.fetchGit ../../PROJECTS/FinUI;
  buildInputs = [
    SDL
    SDL_image
    SDL_ttf
  ];
  CROSS_COMPILE = "armv7l-unknown-linux-gnueabihf-"; # XXX
  UNION_PLATFORM = "rg35xx";
  NIX_CFLAGS_COMPILE = [
    # *sigh*
    "-I${SDL.dev}/include/SDL"
    "-L${placeholder "out"}/lib"
    "-Wno-error"
  ];

  buildPhase = ''
    NIX_CFLAGS_COMPILE+=" -I$out/include"
    # *sigh*
    mkdir -vp $out/{lib,include}
    (cd src/libmsettings
      make $makeFlags "PREFIX=$out"
    )
    (cd src/minui
      make $makeFlags
    )
  '';

  installPhase = ''
    mkdir -vp $out/bin
    (cd src/minui
    mv -v minui.elf $out/bin/minui
    )
  '';
}
