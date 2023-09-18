let
  rev = "caac0eb6bdcad0b32cb2522e03e4002c8975c62e";
  sha256 = "sha256:0vajy7k2jjn1xrhfvqip9c77jvm22pr1y3h8qw4460dz70a4yqy6";
  owner = "NixOS";
  repo = "nixpkgs";
  release = fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
import release
