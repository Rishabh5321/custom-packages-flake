# Custom Packages Flake

A Nix flake containing custom packages for NixOS and Linux.

## Packages

<!-- packages:start -->

| Package | Description |
|---------|-------------|
| `ab-download-manager` | A Download Manager that speeds up your downloads |
| `altersend` | A free, open-source, cross-platform application designed for private, peer-to-peer file transfers |
| `antigravity` | Google Antigravity — an internal Chrome/Electron-based development and onboarding tool |
| `anymex` | AnymeX - Your Anime & Manga Hub |
| `better-control` | Simple control panel for linux based on GTK |
| `brave-origin` | Privacy-oriented browser for Desktop and Laptop computers |
| `fladder` | Simple Jellyfin Frontend built on top of Flutter |
| `grayjay` | Cross-platform application to stream and download content from various sources |
| `helium` | Helium - A simple and modern way to watch anime |
| `hydralauncher` | Game launcher with its own embedded bittorrent client |
| `mangayomi` | Free and open source application for reading manga and watching anime |
| `nuvio` | Nuvio Desktop client (unofficial builds with Linux fixes) |
| `opera` | Faster, safer and smarter web browser |
| `seanime` | Open-source media server with a web interface and desktop app for anime and manga |
| `sorayomi` | A free and open source manga reader for the desktop. |
| `stremio` | Client for Stremio on Linux |
| `stremio-enhanced` | Stremio Enhanced - Stremio with enhanced features |
| `thorium-avx` | Thorium Browser (AVX) - A fast and secure web browser |
| `thorium-avx2` | Thorium Browser (AVX2) - A fast and secure web browser |
| `thorium-sse3` | Thorium Browser (SSE3) - A fast and secure web browser |
| `thorium-sse4` | Thorium Browser (SSE4) - A fast and secure web browser |
| `zcode` | Official Harness for GLM-5.3 - AI coding agent desktop application |

<!-- packages:end -->

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

### Package table

The table under [Packages](#packages) is generated, do not edit it by hand. It is rebuilt
from the packages exposed by the flake using each derivation's `meta.description`.

```bash
./scripts/generate-readme-table.sh          # regenerate the table
./scripts/generate-readme-table.sh --check   # fail if the table is stale
```

The `.github/workflows/flake_format.yml` workflow runs the generator on every push to `main`
and opens a PR with the result.
