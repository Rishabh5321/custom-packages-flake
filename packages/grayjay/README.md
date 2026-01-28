# Grayjay Flake  

[![NixOS](https://img.shields.io/badge/NixOS-supported-blue.svg)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

This repository provides a Nix flake for Grayjay, an open-source media streaming app.

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)

   - [Using the Flake Directly](#using-the-flake-directly)

3. [Configuration](#configuration)
4. [Contributing](#contributing)
5. [License](#license)

---

## Features
- **Pre-built grayjay Package**: The flake provides a pre-built grayjay package for `x86_64-linux`.

---

## Installation

### Using the Flake Directly
You can run grayjay directly using the flake without integrating it into your NixOS configuration:

```bash
nix run github:rishabh5321/custom-packages-flake#grayjay
```
### Using the Flake Profiles

You can install grayjay directly using the flake without integrating it into your NixOS configuration:
```bash
nix profile install github:rishabh5321/custom-packages-flake#grayjay
```
You will the app in the app launcher menu just simply enter to launch.

### Integrating with NixOS declaratively.

You can install this flake directly in declarative meathod.

1. Add the grayjay flake to your flake.nix inputs.
```nix
grayjay.url = "github:rishabh5321/custom-packages-flake";
```
2. Import the grayjay module in your NixOS configuration in home.nix:
```nix
{ inputs, ... }: {
   environment.systemPackages = [  
     inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.grayjay
   ];
}
```
3. Rebuild your system:
```bash
sudo nixos-rebuild switch --flake .#<your-hostname>
```
OR
```bash
nh os boot --hostname <your-hostname> <your-flake-dir>
```
4. Simply start the app using app launcher or using terminal:
```bash
grayjay
```

### License
This flake is licensed under the MIT License. Grayjay itself is licensed under the GPL-3.0 License.

### Acknowledgments
- [Gayjay](https://github.com/futo-org/Grayjay.Desktop) is a multi-platform media application that allows you to watch content from multiple platforms in a single application. Using an extendable plugin system developers can make new integrations with additional platforms. Plugins are cross-compatible between Android and Desktop.
- The NixOS community for their support and resources.
