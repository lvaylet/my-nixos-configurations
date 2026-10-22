# Quickstart & Validation Guide: Integrate MacBook Air M4 Host

**Feature Branch**: `021-integrate-macbook-air` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

This guide documents the runnable validation steps to verify the mutualized configurations across both Linux hosts (`desktop-pc`, `homelab`) and the new macOS host (`macbook-air-m4-15`).

---

## 1. Prerequisites

Ensure you are working in a clone of the repository on the feature branch:

### Bash

```bash
git checkout 021-integrate-macbook-air
```

### Fish

```fish
git checkout 021-integrate-macbook-air
```

---

## 2. Formatting & Static Analysis

Format all Nix expressions and run static linters:

### Bash / Fish

```bash
just fmt
just lint
```

**Expected Outcome**: Zero diffs or formatting changes; `alejandra`, `statix`, and `deadnix` succeed with exit code `0`.

---

## 3. Hermetic Flake Evaluation & Verification

Verify that all host configurations evaluate cleanly across both NixOS (`x86_64-linux`) and Darwin (`aarch64-darwin`) platforms:

### Bash / Fish

```bash
# Verify existing NixOS hosts evaluate without regressions
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath

# Verify new Darwin host evaluates cleanly
nix eval .#darwinConfigurations.macbook-air-m4-15.system.drvPath

# Execute complete repository sandbox checks
just check
```

**Expected Outcome**: All derivations evaluate to `/nix/store/...` paths and `just check` exits with code `0`.

---

## 4. Verify Shared User Environment on Darwin

Verify that the shared modules expose the expected configuration trees to the Darwin host:

### Bash / Fish

```bash
# Check Fish shell aliases (shared from desktop.shell)
nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.fish.shellAliases --json

# Check Git configuration (shared from core.git)
nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.git.settings.diff.algorithm --json

# Check SSH client homelab alias (shared from services.ssh)
nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.ssh.settings.homelab.data.HostName --json

# Check VS Code font configuration (shared from desktop.editors)
nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --apply 'x: x."editor.fontFamily"' --json
```

**Expected Outcome**:

- `fish.shellAliases` includes `ls`, `ll`, `cat`, `y`, `b`.
- `diff.algorithm` evaluates to `"histogram"`.
- `ssh.settings.homelab.HostName` evaluates to `"192.168.1.180"`.
- `editor.fontFamily` evaluates to `"FiraCode Nerd Font"`.

---

## 5. Live Deployment on MacBook Air M4

### First-Time Bootstrap: Initialize `/etc/synthetic.conf`

On a fresh macOS installation, the root filesystem `/` is read-only APFS and does not have `/run`. Initialize `/etc/synthetic.conf` so macOS creates the `/run` synthetic symlink:

#### Bash / Fish

```bash
printf 'run\tprivate/var/run\n' | sudo tee /etc/synthetic.conf
sudo chmod 644 /etc/synthetic.conf
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```

### Routine Operations: Build, Test, and Switch

#### Bash

```bash
# 1. Compile closure only (without activation):
just build-darwin

# 2. Test and activate live in session without creating a new profile generation:
just test-darwin

# 3. Permanently switch and record a new generation:
just switch-darwin
# Or directly using nix-darwin:
nix run nix-darwin -- switch --flake .#macbook-air-m4-15
```

#### Fish

```fish
# 1. Compile closure only (without activation):
just build-darwin

# 2. Test and activate live in session without creating a new profile generation:
just test-darwin

# 3. Permanently switch and record a new generation:
just switch-darwin
# Or directly using nix-darwin:
nix run nix-darwin -- switch --flake .#macbook-air-m4-15
```

### Post-Activation Verification on macOS

1. **Shell**: Open an interactive terminal; confirm Fish launches with the Starship prompt and custom aliases (`eza`, `bat`, etc.).
2. **Editors & Neovim**: Run `nvim`; confirm LazyVim dashboard loads without errors. Launch VS Code; confirm extensions and theme are installed.
3. **Connectivity**: Run `ssh homelab`; confirm connection targets `192.168.1.180` using `~/.ssh/id_ed25519`.
