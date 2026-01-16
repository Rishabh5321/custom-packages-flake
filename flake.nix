{
  description = "Custom Personal Packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
        f {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
        }
      );
    in
    {
      packages = forAllSystems ({ pkgs, ... }:
        import ./packages/default.nix { inherit pkgs; }
      );
    };
}
