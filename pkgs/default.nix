final: super:
let
  inherit (final)
    pkgs
    callPackage
  ;
in
{
  cairo = pkgs.cairo.override({ x11Support = false; glSupport = false; pdfSupport = false; });
  SDL = callPackage ./SDL { inherit (pkgs) SDL; };
  SDL_ttf = callPackage ./SDL_ttf { };
  hello = callPackage ./hello { };
  mkDotApp = callPackage ./mkDotApp { };
}
