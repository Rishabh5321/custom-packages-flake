{ pkgs }:

rec {
  ab-download-manager = pkgs.callPackage ./ab-download-manager/default.nix { };
  better-control = pkgs.callPackage ./better-control/default.nix { };
  fladder = pkgs.callPackage ./fladder/default.nix { };
  anymex = pkgs.callPackage ./anymex/default.nix { };
  playtorrio = pkgs.callPackage ./playtorrio/default.nix { };
  grayjay = pkgs.callPackage ./grayjay/default.nix { };
  seanime = pkgs.callPackage ./seanime/seanime-pkg.nix { };
  surge = pkgs.callPackage ./surge/default.nix { };
  stremio = pkgs.callPackage ./stremio/default.nix { };

  # Zed Editor
  zed-editor = pkgs.callPackage ./zed-editor/default.nix {
    rustPlatform = pkgs.makeRustPlatform {
      cargo = pkgs.rust-bin.stable.latest.default;
      rustc = pkgs.rust-bin.stable.latest.default;
    };
  };
  zed-editor-fhs = zed-editor.fhs;

  zed-editor-preview = pkgs.callPackage ./zed-editor-preview/default.nix {
    rustPlatform = pkgs.makeRustPlatform {
      cargo = pkgs.rust-bin.stable.latest.default;
      rustc = pkgs.rust-bin.stable.latest.default;
    };
  };
  zed-editor-preview-fhs = zed-editor-preview.fhs;

  zed-editor-bin = pkgs.callPackage ./zed-editor-bin/default.nix { };
  zed-editor-bin-fhs = zed-editor-bin.fhs;

  zed-editor-preview-bin = pkgs.callPackage ./zed-editor-preview-bin/default.nix { };
  zed-editor-preview-bin-fhs = zed-editor-preview-bin.fhs;

} // (import ./thorium/default.nix { inherit pkgs; })
