let
  # mksquashfs segfaults here :/
  rev = "ace5093e36ab1e95cb9463863491bee90d5a4183";
  sha256 = "sha256:0scwlhcz9kzl86yqrdk1hc3fjbli6yxyd0na9qn4q5cm53nzdqg6";
  # mksquashfs segfaults here :/
#  rev = "caac0eb6bdcad0b32cb2522e03e4002c8975c62e";
#  sha256 = "sha256:0vajy7k2jjn1xrhfvqip9c77jvm22pr1y3h8qw4460dz70a4yqy6";
  # mksquashfs segfaults here :/
#  rev = "1d416595adfc7d48ef06ee49ffd2d9efee2c8859";
#  sha256 = "sha256:1y29s8cldhhpv9mb93hnfnz0v26i4vy1qzs91vrc2mwkspdskh51";
  # mksquashfs segfaults here :/
#  rev = "afb90daf43804223e86014a906c207bd25d4fd70";
#  sha256 = "sha256:1isb9ycryyswajy1rz9r3db2hxsn36ayzgnyjd01aipcwzl48hgp";

  owner = "NixOS";
  repo = "nixpkgs";
  release = fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    inherit sha256;
  };
in
import release
