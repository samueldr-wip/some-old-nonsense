{ SDL
, fetchpatch
}:

let
  rev = "cd2bf2b59143817408db225e9826564420b35872";
  miyooCFW = patch: sha256: fetchpatch {
    url = "https://github.com/shauninman/union-rg35xx-toolchain/raw/${rev}/support/patches/package/sdl/${patch}";
    inherit sha256;
  };
in

SDL.overrideAttrs({ patches, ... }: {
  patches = patches ++ [
    (miyooCFW "0003-rg35xx-sdlk-additions.patch" "sha256-ioMufwogJYNDhUdfvBrHuRS59Vg3XLdrF2lAnyApidA=")
    (miyooCFW "0004-modernize-SDL_FBCON_DONT_CLEAR.patch" "sha256-HLsrE/UtJBaekl+0/ZXhgU8vzqOWfgYfwuB8nuHZSsk=")
  ];
})
