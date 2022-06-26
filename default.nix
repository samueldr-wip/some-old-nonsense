{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) callPackage;
  self = {
    rootfs = callPackage ./pkgs/rootfs.nix {};
    editSquashfs = callPackage ./pkgs/edit-squashfs.nix {};
    finalRootfs = callPackage ./pkgs/final-rootfs {
      inherit (self) rootfs editSquashfs;
    };
    firmwareUpgrade = callPackage ./pkgs/firmware-upgrade.nix {
      rootfs = "${self.finalRootfs}/rootfs.img";
    };
  };
in
  self
