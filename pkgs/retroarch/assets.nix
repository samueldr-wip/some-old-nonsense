{ stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "retroarch-assets";
  version = "2022-10-24";

  src = fetchFromGitHub {
    owner = "libretro";
    repo = "retroarch-assets";
    rev = "4ec80faf1b5439d1654f407805bb66141b880826";
    sha256 = "sha256-j1npVKEknq7hpFr/XfST2GNHI5KnEYjZAM0dw4tMsYk=";
  };

  makeFlags = [
    "INSTALLDIR=${placeholder "out"}"
  ];
}
