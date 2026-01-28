# Thorium Flake

[![NixOS](https://img.shields.io/badge/NixOS-supported-blue.svg)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Thorium Nix Flake Documentation

This Nix Flake provides multiple versions of the Thorium browser, optimized for different CPU instruction sets. You can choose the version that best matches your CPU's capabilities for improved performance.


## Table of Contents
1. [Features](#features)
2. [Installation](#installation)

   - [Using the Flake Directly](#using-the-flake-directly)

3. [Configuration](#configuration)
4. [Contributing](#contributing)
5. [License](#license)

## Features
- **Pre-built Thorium Package**: The flake provides a pre-built Thorium package for `x86_64-linux`.
- **Contains all versions**: This flake contains all the supported version of Thorium select the best version for your computer.

## Installation

### Using the Flake Profiles

You can install this flake directly in declarative meathod.

```bash
# For AVX2 (modern CPUs)
nix profile install github:Rishabh5321/custom-packages-flake#thorium-avx2

# For AVX (older CPUs)
nix profile install github:Rishabh5321/custom-packages-flake#thorium-avx

# For SSE4 (legacy CPUs)
nix profile install github:Rishabh5321/custom-packages-flake#thorium-sse4

# For SSE3 (very old CPUs)
nix profile install github:Rishabh5321/custom-packages-flake#thorium-sse3
```

### Integrating with NixOS declaratively.

1. Ensure you have flakes enabled in your NixOS configuration.

2. Add this flake to your `flake.nix`:

   ```nix
   {
     inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Note that nixos unstable channel is required
        custom-packages.url = "github:Rishabh5321/custom-packages-flake";
     };

     outputs = { self, nixpkgs }: {
       # Your existing configuration...
       
       nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
         # ...
         modules = [
           # Add inputs.thorium.packages.${system}.thorium-version you want to install only choose one
          ({ pkgs, inputs, ... }: {
            environment.systemPackages = [ 
              inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.thorium-avx
            ];
          })
         ];
       };
     };
   }
   ```

3. Run `sudo nixos-rebuild switch` to apply the changes. It can also be registered with home manager

### Contributing

Contributions to this flake are welcome! Here’s how you can contribute:
1. Fork the repository.
2. Create a new branch for your changes:
```bash
git checkout -b my-feature
```
3. Commit your changes:
```bash
git commit -m "Add my feature"
```
4. Push the branch to your fork:
```bash
git push origin my-feature
```
5. Open a pull request on GitHub.

### License
This flake is licensed under the MIT License. Thorium itself is licensed under the BSD 3-Clause License.

### Acknowledgments
- [Thorium](https://github.com/Alex313031/thorium) Chromium fork for linux named after radioactive element No. 90.
- The NixOS community for their support and resources.
