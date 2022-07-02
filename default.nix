{ pkgs ? import ./nixpkgs.nix {} }:

let
  inherit (pkgs) callPackage;
  targetPkgs = pkgs.pkgsCross.armv7l-hf-multiplatform;

  self = {
    rootfs = callPackage ./pkgs/rootfs.nix {};
    editSquashfs = callPackage ./pkgs/edit-squashfs.nix {};
    finalRootfs = callPackage ./pkgs/final-rootfs {
      inherit (self) rootfs editSquashfs;
    };
    firmwareUpgrade = callPackage ./pkgs/firmware-upgrade.nix {
      rootfs = "${self.finalRootfs}/rootfs.img";
    };
    FHSBuilder = callPackage ./pkgs/fhsbuilder {
      inherit targetPkgs;
      libc = self.glibc;
    };
    glibc = targetPkgs.callPackage ./pkgs/glibc {
      inherit (self) FHSBuilder;
    };
    busybox = targetPkgs.callPackage ./pkgs/busybox {
      inherit (self) FHSBuilder;
    };
    hello = targetPkgs.callPackage ./pkgs/hello {
      inherit (self) FHSBuilder;
    };
  };
in
  self
