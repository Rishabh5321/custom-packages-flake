# Helium Flake

This repository provides a Nix flake for [Helium](https://github.com/imputnet/helium-linux), a chromuim based browser

## Usage

### Run Directly

You can run Helium directly without installing it:

```bash
nix run github:Rishabh5321/custom-packages-flake#helium
```

### Install with Nix Profile

To install it into your user profile:

```bash
nix profile install github:Rishabh5321/custom-packages-flake#helium
```

### Add to NixOS Configuration

To add Helium to your NixOS configuration, add this repository to your flake inputs and then add the package to your explicitly installed packages.

1. Add to `inputs` in `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    custom-packages.url = "github:Rishabh5321/custom-packages-flake";
  };
}
```

2. Add to `environment.systemPackages`:

```nix
{
  environment.systemPackages = [
    inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.helium
  ];
}
```

## Information

- **Upstream**: [imputnet/helium-linux](https://github.com/imputnet/helium-linux)
