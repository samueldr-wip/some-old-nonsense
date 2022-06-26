{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) callPackage;
  self = {
    rootfs = callPackage ./pkgs/rootfs.nix {};
    editSquashfs = callPackage ./pkgs/edit-squashfs.nix {};
    finalRootfs = callPackage ./pkgs/final-rootfs {
      inherit (self) rootfs editSquashfs;
    };
  };
in
  self
