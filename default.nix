{ pkgs ? import <nixpkgs> {} }:

pkgs.callPackage ./rootfs.nix {}
