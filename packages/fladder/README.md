# Fladder Flake

This repository provides a Nix flake for [Fladder](https://github.com/DonutWare/Fladder), a simple Jellyfin frontend built with Flutter. It packages the official AppImage release for use with Nix/NixOS.

## Usage

### Run Directly

You can run the application directly without installing it:

```bash
nix run github:Rishabh5321/custom-packages-flake#fladder
```

### Install with Nix Profile

To install it into your user profile:

```bash
nix profile install github:Rishabh5321/custom-packages-flake
```

### Add to NixOS Configuration

To add Fladder to your NixOS configuration, add this repository to your flake inputs and then add the package to your explicitly installed packages.

1. Add to `inputs` in `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    fladder.url = "github:Rishabh5321/custom-packages-flake";
    fladder.inputs.nixpkgs.follows = "nixpkgs";
  };
  
  outputs = { self, nixpkgs, fladder, ... }: {
    # ...
  };
}
```

2. Add to `environment.systemPackages`:

```nix
{
  environment.systemPackages = [
    inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.fladder
  ];
}
```

### Add to Home Manager

If you are using Home Manager:

1. Add the input as shown above.
2. Add to `home.packages`:

```nix
{
  home.packages = [
    inputs.fladder.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

## Build Locally

To build the package locally from this repository:

```bash
nix build
```

The result will be in the `./result` directory.

## Information

- **Upstream**: [DonutWare/Fladder](https://github.com/DonutWare/Fladder)
