# Data Model: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Feature**: `027-refactor-core-modules`
**Date**: 2026-10-26

## Configuration Entities & Module Attributes

### 1. `flake.modules.core.limine` (`modules/core/bootloader.nix`)

- **Domain**: `core`
- **Target**: `nixos`
- **Attributes**:
  - `boot.loader.efi.canTouchEfiVariables = true`
  - `boot.loader.limine.enable = true`
  - `boot.loader.limine.maxGenerations = 5`
  - `boot.loader.limine.extraConfig` (`remember_last_entry: yes`)
  - `boot.loader.limine.extraEntries` (Windows 11 EFI chainload entry)
  - `boot.loader.limine.style.wallpapers` (5 NixOS artwork wallpapers)
- **Consumed by**: `modules/hosts/desktop-pc.nix`

### 2. `flake.modules.core.grub` (`modules/core/bootloader.nix`)

- **Domain**: `core`
- **Target**: `nixos`
- **Attributes**:
  - `boot.loader.efi.canTouchEfiVariables = false`
  - `boot.loader.grub.enable = true`
  - `boot.loader.grub.efiSupport = true`
  - `boot.loader.grub.efiInstallAsRemovable = true`
- **Consumed by**: `modules/hosts/homelab.nix`

### 3. Shared Shell Shortcuts (`modules/core/base.nix`)

- **Bindings**:
  - `systemdAliases`: 17 `systemctl` and `journalctl` shortcuts (NixOS only)
  - `gitAliases`: 40 Oh-My-Zsh style `git` shortcuts (shared across NixOS and Darwin)
- **Outputs**:
  - `nixos.environment.shellAliases = systemdAliases // gitAliases`
  - `nixos.programs.fish.shellAbbrs = systemdAliases // gitAliases`
  - `darwin.environment.shellAliases = gitAliases`
  - `darwin.programs.fish.shellAbbrs = gitAliases`

### 4. SSH Client Host Identity (`modules/services/ssh.nix`)

- **Domain**: `services`
- **Target**: `homeManager`
- **Attributes**:
  - `programs.ssh.settings.homelab.User = vars.userName`
- **Consumed by**: `desktop-pc` and `macbook-air-m4-15`
