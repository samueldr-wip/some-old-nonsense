final: super:
let
  inherit (final)
    pkgs
    callPackage
  ;
in
{
  cairo = pkgs.cairo.override({ x11Support = false; glSupport = false; pdfSupport = false; });
  SDL = callPackage ./SDL { inherit (pkgs) SDL; };
  SDL_ttf = callPackage ./SDL_ttf { };
  SDL_image = pkgs.SDL_image.override({ inherit (final) SDL; });
  hello = callPackage ./hello { };
  hello_packaged =
    callPackage (
    { mkDotApp
    , dotAppToMiniUIPak
    , hello
    }:

    let
      app = mkDotApp {
        name = "hello";
        entrypoint = "${hello}/bin/stub-boot-ui";
        paths = [
          hello
        ];
      };
    in
      dotAppToMiniUIPak { inherit app; }
  ) { };

  minui = callPackage ./minui { };
  minui_packaged =
    callPackage (
    { mkDotApp
    , dotAppToMiniUIPak
    , minui
    }:

    let
      app = mkDotApp {
        name = "minui";
        entrypoint = "${minui}/bin/minui";
        paths = [
          minui
        ];
      };
    in
      dotAppToMiniUIPak { inherit app; }
  ) { };

  minarch = callPackage ./minarch { };
  minarch_packaged =
    callPackage (
    { mkDotApp
    , dotAppToMiniUIPak
    , minarch
    }:

    let
      app = mkDotApp {
        name = "minarch";
        entrypoint = "${minarch}/bin/minarch";
        paths = [
          minarch
        ];
      };
    in
      dotAppToMiniUIPak { inherit app; }
  ) { };

  dotAppToMiniUIPak = callPackage ./dotAppToMiniUIPak { };
  mkDotApp = callPackage ./mkDotApp { };


  retroarch = callPackage ../pkgs/retroarch { };
  retroarch-assets = callPackage ../pkgs/retroarch/assets.nix { };
  retroarchWrapped = callPackage ../pkgs/retroarch/wrapped.nix {
    cores = with (pkgs.libretro.override { inherit (final) retroarch; }); [
      fceumm
      gambatte
      snes9x2005-plus
      #(pcsx-rearmed.overrideAttrs({ makeFlags ? [], ... }: {
      #  makeFlags = makeFlags ++ [
      #    "DYNAREC=ari64"
      #  ];
      #}))
      #(gpsp.overrideAttrs({ makeFlags ? [], patches ? [], ... }: {
      #  # These borrowed patches adds a sensible armv7 platform to target.
      #  # The one we want (miyoomini) depends on the other.
      #  patches = patches ++ [
      #    (self.fetchpatch {
      #      url = "https://github.com/shauninman/picoarch/raw/ab7f0294377178a2db77d4adf44e7691f532f1a1/patches/gpsp/1000-trimui-build.patch";
      #      sha256 = "sha256-Kv9gceaifcoNIbQx53gLqgFewe56vshKKKGGmAm4IVY=";
      #    })
      #    (self.fetchpatch {
      #      url = "https://github.com/shauninman/picoarch/raw/ab7f0294377178a2db77d4adf44e7691f532f1a1/patches/gpsp/1001-miyoomini-build.patch";
      #      sha256 = "sha256-nx0Ws9fyVwQFN4vr+u1E+FtJCT4f64LSUoarsyQtXpA=";
      #    })
      #  ];
      #  makeFlags = makeFlags ++ [
      #    "CROSS_COMPILE=${self.stdenv.cc.targetPrefix}"
      #    "platform=miyoomini"
      #  ];
      #}))
      #(picodrive.overrideAttrs({ makeFlags ? [], ... }: {
      #  src = builtins.fetchGit {
      #    url = ../../../../projects/libretro-picodrive;
      #    submodules = true;
      #  };
      #  # For building `cyclone_gen`, a build-time tool
      #  depsBuildBuild = [ self.buildPackages.stdenv.cc ];
      #  makeFlags = makeFlags ++ [
      #  ];
      #}))
    ];
  };
  retroarch_packaged =
    callPackage (
    { mkDotApp
    , dotAppToMiniUIPak
    , retroarchWrapped
    }:

    let
      app = mkDotApp {
        name = "retroarch";
        entrypoint = "${retroarchWrapped}/bin/retroarch";
        paths = [
          retroarchWrapped
        ];
      };
    in
      dotAppToMiniUIPak { inherit app; }
  ) { };

}
