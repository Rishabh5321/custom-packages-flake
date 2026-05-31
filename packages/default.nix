{ pkgs }:

rec {
  ab-download-manager = pkgs.callPackage ./ab-download-manager/default.nix { };
  better-control = pkgs.callPackage ./better-control/default.nix { };
  fladder = pkgs.callPackage ./fladder/default.nix { };
  antigravity = pkgs.callPackage ./antigravity/default.nix { };
  brave-origin = pkgs.callPackage ./brave-origin/default.nix { };
  anymex = pkgs.callPackage ./anymex/default.nix { };
  playtorrio = pkgs.callPackage ./playtorrio/default.nix { };
  playtorrio-v2 = pkgs.callPackage ./playtorrio-v2/default.nix { };
  mangayomi = pkgs.callPackage ./mangayomi/default.nix { };
  sorayomi = pkgs.callPackage ./sorayomi/default.nix { };
  grayjay = pkgs.callPackage ./grayjay/default.nix { };
  seanime = pkgs.callPackage ./seanime/seanime-pkg.nix { };
  stremio = pkgs.callPackage ./stremio/default.nix { };
  stremio-enhanced = pkgs.callPackage ./stremio-enhanced/default.nix { };
  helium = pkgs.callPackage ./helium/default.nix { };
  hydralauncher = pkgs.callPackage ./hydralauncher/default.nix { };
  shonenx = pkgs.callPackage ./shonenx/default.nix { };
  opera = pkgs.callPackage ./opera/default.nix { };
  skystream = pkgs.callPackage ./skystream/default.nix { };
  surge = pkgs.callPackage ./surge/default.nix { };


} // (import ./thorium/default.nix { inherit pkgs; })
