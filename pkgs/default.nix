final: super:
let
  inherit (final)
    pkgs
    callPackage
  ;
in
{
  SDL = callPackage ./SDL { inherit (pkgs) SDL; };
  SDL_ttf = callPackage ./SDL_ttf { };
  hello = callPackage ./hello { };
}
