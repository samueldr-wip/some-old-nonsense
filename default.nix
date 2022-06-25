{ pkgs ? import <nixpkgs> {} }:

let
  self = {
    rootfs = pkgs.callPackage ./pkgs/rootfs.nix {};
  };
in
  self
