# Custom Packages Flake

A Nix flake containing custom packages for NixOS and Linux.

## Packages

| Package | Description |
|---------|-------------|
| `thorium-avx` | Thorium Browser (AVX optimized) |
| `thorium-avx2` | Thorium Browser (AVX2 optimized) |
| `thorium-sse3` | Thorium Browser (SSE3 optimized) |
| `thorium-sse4` | Thorium Browser (SSE4 optimized) |
| `seanime` | Open-source media server for anime and manga |
| `fladder` | A Simple Jellyfin Frontend built on top of Flutter |
| `playtorrio` | Stream torrents directly |
| `better-control` | Simple control panel for Linux based on GTK |
| `ab-download-manager` | A Download Manager that speeds up your downloads |

## Usage

### Run directly
You can run any package directly without installing:

```bash
nix run github:Rishabh5321/custom-packages-flake#thorium
nix run github:Rishabh5321/custom-packages-flake#seanime
```

### Install in Profile
To install a package into your user profile:

```bash
nix profile install github:Rishabh5321/custom-packages-flake#fladder
```

### NixOS Configuration
Add this flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    custom-packages.url = "github:Rishabh5321/custom-packages-flake";
  };

  outputs = { self, nixpkgs, custom-packages, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            custom-packages.packages.${pkgs.system}.thorium
            custom-packages.packages.${pkgs.system}.better-control
          ];
        })
      ];
    };
  };
}
```

## Automated Updates

This repository features a fully automated update system. A GitHub Actions workflow runs daily to check for upstream updates.

- **Workflow**: `.github/workflows/update-packages.yml`
- **Mechanism**: The workflow executes custom `update.sh` scripts located in each package directory (e.g., `packages/thorium/update.sh`).
- **Pull Requests**: When an update is detected, a Pull Request is automatically created and merged.
