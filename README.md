# Custom Packages Flake

A Nix flake containing custom packages for NixOS and Linux.

## Packages

| Package | Description |
|---------|-------------|
| `ab-download-manager` | A Download Manager that speeds up your downloads |
| `antigravity` | Google Antigravity — an internal Chrome/Electron-based development and onboarding tool |
| `anymex` | Anime Streaming App |
| `better-control` | Simple control panel for Linux based on GTK |
| `fladder` | A Simple Jellyfin Frontend built on top of Flutter |
| `grayjay` | Desktop client for Grayjay to stream and download video content |
| `hydralauncher` | Open source game launcher |
| `mangayomi` | Free and open source application for reading manga and watching anime |
| `playtorrio` | Stream torrents directly |
| `seanime` | Open-source media server for anime and manga |
| `shonenx` | Anime Streaming Desktop App |
| `sorayomi` | A free and open source manga reader for the desktop |
| `stremio` | Open-source media player |
| `surge` | Open-source media server for anime and manga (TUI) |
| `thorium-avx` | Thorium Browser (AVX optimized) |
| `thorium-avx2` | Thorium Browser (AVX2 optimized) |
| `thorium-sse3` | Thorium Browser (SSE3 optimized) |
| `thorium-sse4` | Thorium Browser (SSE4 optimized) |

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
        ({ inputs, pkgs, ... }: {
          environment.systemPackages = [
            inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.fladder
            inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.better-control
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
