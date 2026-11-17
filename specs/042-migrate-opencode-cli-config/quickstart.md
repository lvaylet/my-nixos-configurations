# Quickstart & Validation Guide: OpenCode 2 CLI Configuration Migration

**Feature**: `042-migrate-opencode-cli-config`
**Date**: 2026-11-17
**Branch**: `042-migrate-opencode-cli-config`

---

## 1. Overview

This guide provides end-to-end scenarios to validate the elimination of the OpenCode 2 evaluation warning and verify that client configuration (`cli.json`) correctly maintains the Nord theme across desktop and server hosts.

---

## 2. Prerequisites

- Repository cloned on an operator machine with Nix Flakes and `just` installed.
- Active git branch: `042-migrate-opencode-cli-config`.

---

## 3. Validation Scenarios

### Scenario 1: Quality Gates & Formatting

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
- All commands exit with code 0 and zero warnings.

---

### Scenario 2: Warning-Free Flake Evaluation

Verify that all machine configurations evaluate cleanly with zero OpenCode deprecation warnings.

#### Bash

```bash
# Evaluate desktop-pc
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# Evaluate homelab
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# Evaluate macbook-air-m4-15
nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath
```

#### Fish

```fish
# Evaluate desktop-pc
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# Evaluate homelab
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# Evaluate macbook-air-m4-15
nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath
```

**Expected Outcome**:
- Derivation paths are printed.
- Zero evaluation warnings regarding `programs.opencode.tui` or `cli.json` are emitted.

---

### Scenario 3: Verify Declarative CLI Configuration Content

Verify that Home Manager and tmpfiles rules generate `cli.json` containing the Nord theme.

#### Bash

```bash
# Inspect desktop-pc evaluated Home Manager cli configuration
nix eval --json .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.opencode.cli
```

#### Fish

```fish
# Inspect desktop-pc evaluated Home Manager cli configuration
nix eval --json .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.opencode.cli
```

**Expected Outcome**:
- Output matches: `{"theme":{"name":"nord"}}`.

---

### Scenario 4: Live Activation Testing

Verify that activation testing completes successfully on the target machine without errors.

#### Bash

```bash
just test configuration="desktop-pc"
```

#### Fish

```fish
just test configuration="desktop-pc"
```

**Expected Outcome**:
- `nh os test` builds and activates the profile.
- `$HOME/.config/opencode/cli.json` exists and contains `{"$schema":"https://opencode.ai/v2/cli.json","theme":{"name":"nord"}}`.
- No evaluation warnings are emitted.
