{ pkgs }:

{
  ab-download-manager = pkgs.callPackage ./ab-download-manager/default.nix { };
  better-control = pkgs.callPackage ./better-control/default.nix { };
  fladder = pkgs.callPackage ./fladder/default.nix { };
  playtorrio = pkgs.callPackage ./playtorrio/default.nix { };
  seanime = pkgs.callPackage ./seanime/seanime-pkg.nix { };
} // (pkgs.callPackage ./thorium/default.nix { })
