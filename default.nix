{ pkgs ? import ./pkgs.nix {} }:
let pkgs' = pkgs; in
let
  inherit (pkgs) lib;
  pkgs = pkgs'.pkgsCross.armv7l-hf-multiplatform;

  # Makes an "overlay-like" newScope-like thing.
  pkgsSet =
    let
      set = lib.makeExtensible (
        self:
        {
          inherit pkgs;
          callPackage = pkgs.newScope self;
        }
      );
    in
      set.extend
  ;
in
(
pkgsSet (import ./pkgs)
).extend (
  final: super: {}
  # XXX RG35XX stuff here
  # XXX or really, device-specific...
  # SDL = ...
)
