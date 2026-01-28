# Better-Control Flake

## NOTE:- Better-control is available in the nixpkgs repository. This flake will follow commits of the main project and merge them automatically after build checks.

[![NixOS](https://img.shields.io/badge/NixOS-supported-blue.svg)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

NOTE :- Please Enable `services.power-profiles-daemon.enable = true;` if you are having power profile changing issues.

NOTE:- Please enable `services.usbguard.enable = true;` if you want USBGuard to work. Additionally, you will need to update your usbguard permissions to use USBGuard. For reference, see my configuration file: [usbguard.nix](./usbguard.nix). Change ${username} with your username.

NOTE:- Please enable `services.upower.enable = true;` if battery stats are not visible in better-control battery panel.

## Table of Contents
1. [Features](#features)
2. [Installation](#installation)
   - [Using the Nix Run](#run-the-application-without-installing)
   - [Using the Flake Profiles](#using-the-flake-profiles)
   - [Using the Flake Directly](#integrating-with-nixos-declaratively)

3. [Configuration](#configuration)
4. [Contributing](#contributing)
5. [License](#license)

---

## Features
- **Pre-built better-control Package**: The flake provides a pre-built better-control package for `x86_64-linux`.

---

## Installation

### Run the application without installing 

You can run the app directly by using nix run
```bash
nix run github:Rishabh5321/custom-packages-flake#better-control
```

### Using the Flake Profiles

You can install better-control directly using the flake without integrating it into your NixOS configuration:
```bash
nix profile install github:rishabh5321/custom-packages-flake#better-control
```
You will the app in the app launcher menu just simply enter to launch.

### Integrating with NixOS declaratively.

You can install this flake directly in declarative meathod.

1. Add the Better-Control flake to your flake.nix inputs.
```nix
custom-packages.url = "github:rishabh5321/custom-packages-flake";
```
2. Import the Better-Control module in your NixOS configuration where you declare pkgs:
```nix
{ inputs, pkgs ... }: {
   environment.systemPackages =
      with pkgs; [
         inputs.custom-packages.packages.${pkgs.stdenv.hostPlatform.system}.better-control
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
better-control
```

### License
This flake is licensed under the MIT License. Better-control itself is licensed under the GPL-3.0 License.

### Acknowledgments
- [Better-control](https://github.com/better-ecosystem/better-control) GTK-themed control panel for Linux 🐧
- The NixOS community for their support and resources.
