# Playtorrio Flake

This repository provides a Nix flake for Playtorrio, packaged from the upstream AppImage.

## Description

Playtorrio is an entertainment hub application. This flake wraps the official AppImage release to make it easily runnable on NixOS and other Linux distributions using the Nix package manager.

## Usage

### Install to Profile

To install Playtorrio to your user profile:

```bash
nix profile install github:Rishabh5321/custom-packages-flake#playtorrio
```

### Run Directly

You can run Playtorrio directly without installing it:

```bash
nix run github:Rishabh5321/custom-packages-flake#playtorrio
```

### Add to NixOS Configuration

To add Playtorrio to your NixOS configuration, add this repository to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    playtorrio.url = "github:Rishabh5321/custom-packages-flake";
  };

  outputs = { self, nixpkgs, playtorrio, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ pkgs, inputs,... }: {
          environment.systemPackages = [
            inputs.playtorrio.packages.${pkgs.stdenv.hostPlatform.system}.playtorrio
          ];
        })
      ];
    };
  };
}
```

## Upstream

This flake packages the application from: https://github.com/ayman708-UX/PlayTorrio
