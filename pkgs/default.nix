final: super:
let
  inherit (final)
    pkgs
    callPackage
  ;
in
{
  SDL = callPackage ./SDL { inherit (pkgs) SDL; };
}
