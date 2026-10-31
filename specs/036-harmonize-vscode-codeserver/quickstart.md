# Quickstart & Validation Guide: Harmonized Visual Studio Code and Code Server Configurations

**Feature**: `036-harmonize-vscode-codeserver`
**Date**: 2026-10-31
**Branch**: `036-harmonize-vscode-codeserver`

---

## 1. Overview

This guide provides end-to-end scenarios to validate the implementation of shared VS Code and Code Server configurations across `desktop-pc` and `homelab`.

---

## 2. Prerequisites

- Repository cloned on an operator machine with Nix Flakes and `just` installed.
- Active git branch: `036-harmonize-vscode-codeserver`.

---

## 3. Validation Scenarios

### Scenario 1: Static Analysis, Formatting & Sandbox Verification

Verify that all Nix files format cleanly with `alejandra`, pass static linting (`statix`, `deadnix`), and succeed in hermetic pre-commit checks.

#### Bash

```bash
just fmt
just lint
just check
```

#### Fish

```fish
just fmt
just lint
just check
```

**Expected Outcome**:

- All commands exit with code 0 and zero errors or warnings.

---

### Scenario 2: Flake Evaluation & Shared Output Parity

Verify that `outputs.lib.vscode` is exposed and both host configurations evaluate the exact same settings and extensions.

#### Bash

```bash
# Verify shared settings evaluation
nix eval .#lib.vscode.settings --apply 'builtins.attrNames' --json

# Verify desktop-pc Home Manager userSettings
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --apply 'x: x."workbench.colorTheme"' --json

# Verify homelab code-server wrapped package and extensions
nix eval .#nixosConfigurations.homelab.config.services.code-server.package.name --raw
nix eval .#nixosConfigurations.homelab.config.services.code-server.extraPackages --apply 'map (p: p.name)' --json
```

#### Fish

```fish
# Verify shared settings evaluation
nix eval .#lib.vscode.settings --apply 'builtins.attrNames' --json

# Verify desktop-pc Home Manager userSettings
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --apply 'x: x."workbench.colorTheme"' --json

# Verify homelab code-server wrapped package and extensions
nix eval .#nixosConfigurations.homelab.config.services.code-server.package.name --raw
nix eval .#nixosConfigurations.homelab.config.services.code-server.extraPackages --apply 'map (p: p.name)' --json
```

**Expected Outcome**:

- `workbench.colorTheme` outputs `"Nord"`.
- `services.code-server.package.name` outputs `"code-server-with-extensions-..."`.
- `services.code-server.extraPackages` includes `alejandra` and `nixd`.

---

### Scenario 3: Homelab `systemd.tmpfiles.rules` Settings Symlink Verification

Verify that declarative `settings.json` symlinks are configured on `homelab`.

#### Bash

```bash
nix eval .#nixosConfigurations.homelab.config.systemd.tmpfiles.rules --apply 'rules: builtins.filter (r: builtins.match ".*settings\\.json.*" r != null) rules' --json
```

#### Fish

```fish
nix eval .#nixosConfigurations.homelab.config.systemd.tmpfiles.rules --apply 'rules: builtins.filter (r: builtins.match ".*settings\\.json.*" r != null) rules' --json
```

**Expected Outcome**:

- Output contains rules creating `~/.local/share/code-server/User/settings.json` and `~/.config/code-server/settings.json` pointing to the generated Nix store JSON derivation.

---

### Scenario 4: Non-Switching Activation Testing on Target Hosts

Verify that configuration changes can be activated safely without modifying the bootloader.

#### Bash

```bash
# Test on desktop-pc (when running locally on desktop-pc)
just test configuration="desktop-pc"

# Test on homelab (when running on or targeting homelab)
just test configuration="homelab"
```

#### Fish

```fish
# Test on desktop-pc (when running locally on desktop-pc)
just test configuration="desktop-pc"

# Test on homelab (when running on or targeting homelab)
just test configuration="homelab"
```

**Expected Outcome**:

- Generation builds and activates successfully without errors.
- On `homelab`, `code-server.service` starts and loads with the Nord theme, extensions, and relative line numbers.
