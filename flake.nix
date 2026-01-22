{
  description = "Custom Personal Packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # inputs.rust-overlay.url = "github:oxalica/rust-overlay";
  # inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
        f {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
            # overlays = [ rust-overlay.overlays.default ];
            config.allowUnfree = true;
          };
        }
      );
    in
    {
      packages = forAllSystems ({ pkgs, ... }:
        import ./packages/default.nix { inherit pkgs; }
      );

      nixosModules.seanime = { ... }: {
        imports = [
          ({ ... }: {
            imports = [ ./packages/seanime/seanime-home.nix ];
            config = {
              _module.args.seanime = self.packages.x86_64-linux.seanime;
            };
          })
        ];
      };
    };
}
