{ pkgs }:

rec {
  ab-download-manager = pkgs.callPackage ./ab-download-manager/default.nix { };
  better-control = pkgs.callPackage ./better-control/default.nix { };
  fladder = pkgs.callPackage ./fladder/default.nix { };
  antigravity = pkgs.callPackage ./antigravity/default.nix { };
  altersend = pkgs.callPackage ./altersend/default.nix { };
  brave-origin = pkgs.callPackage ./brave-origin/default.nix { };
  cage-xtmapper = pkgs.callPackage ./cage-xtmapper/default.nix { };
  anymex = pkgs.callPackage ./anymex/default.nix { };
  mangayomi = pkgs.callPackage ./mangayomi/default.nix { };
  nuvio = pkgs.callPackage ./nuvio/default.nix { };
  sorayomi = pkgs.callPackage ./sorayomi/default.nix { };
  seanime = pkgs.callPackage ./seanime/seanime-pkg.nix { };
  stremio = pkgs.callPackage ./stremio/default.nix { };
  stremio-enhanced = pkgs.callPackage ./stremio-enhanced/default.nix { };
  helium = pkgs.callPackage ./helium/default.nix { };
  hydralauncher = pkgs.callPackage ./hydralauncher/default.nix { };
  opera = pkgs.callPackage ./opera/default.nix { };
  zcode = pkgs.callPackage ./zcode/default.nix { };

} // (import ./thorium/default.nix { inherit pkgs; })
