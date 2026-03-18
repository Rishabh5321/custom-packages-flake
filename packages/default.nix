{ pkgs }:

rec {
  ab-download-manager = pkgs.callPackage ./ab-download-manager/default.nix { };
  better-control = pkgs.callPackage ./better-control/default.nix { };
  fladder = pkgs.callPackage ./fladder/default.nix { };
  antigravity = pkgs.callPackage ./antigravity/default.nix { };
  anymex = pkgs.callPackage ./anymex/default.nix { };
  playtorrio = pkgs.callPackage ./playtorrio/default.nix { };
  mangayomi = pkgs.callPackage ./mangayomi/default.nix { };
  sorayomi = pkgs.callPackage ./sorayomi/default.nix { };
  grayjay = pkgs.callPackage ./grayjay/default.nix { };
  seanime = pkgs.callPackage ./seanime/seanime-pkg.nix { };
  surge = pkgs.callPackage ./surge/default.nix { };
  stremio = pkgs.callPackage ./stremio/default.nix { };
  hydralauncher = pkgs.callPackage ./hydralauncher/default.nix { };
  shonenx = pkgs.callPackage ./shonenx/default.nix { };
  opera = pkgs.callPackage ./opera/default.nix { };


} // (import ./thorium/default.nix { inherit pkgs; })
