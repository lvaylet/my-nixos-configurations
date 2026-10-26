# Quickstart & Validation Guide: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Feature**: `027-refactor-core-modules`
**Date**: 2026-10-26

## Verification Commands

### 1. Format & Lint Checks

**Bash / Fish**:

```sh
just fmt
just lint
```

### 2. Bootloader Decoupling Verification

Verify that `desktop-pc` enables Limine and `homelab` enables GRUB 2 without `lib.mkForce`:

**Bash / Fish**:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.boot.loader.limine.enable
# Expected: true

nix eval .#nixosConfigurations.desktop-pc.config.boot.loader.grub.enable
# Expected: false

nix eval .#nixosConfigurations.homelab.config.boot.loader.limine.enable
# Expected: false

nix eval .#nixosConfigurations.homelab.config.boot.loader.grub.enable
# Expected: true
```

### 3. Fish Abbreviations & Alias Deduplication Verification

Verify that `programs.fish.shellAbbrs` is populated on both NixOS (`desktop-pc`, `homelab`) and Darwin (`macbook-air-m4-15`):

**Bash / Fish**:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.programs.fish.shellAbbrs.gco
# Expected: "git checkout"

nix eval .#nixosConfigurations.homelab.config.programs.fish.shellAbbrs.scs
# Expected: "systemctl status"

nix eval .#darwinConfigurations.macbook-air-m4-15.config.programs.fish.shellAbbrs.gst
# Expected: "git status"
```

### 4. SSH Identity Verification

Verify that `programs.ssh.settings.homelab.User` resolves via `vars.userName`:

**Bash / Fish**:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.ssh.settings.homelab.data.User
# Expected: "laurent"

nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.ssh.settings.homelab.data.User
# Expected: "laurent"
```

### 5. Full Flake Evaluation & Pre-Commit Sandbox Check

**Bash / Fish**:

```sh
just check
```
