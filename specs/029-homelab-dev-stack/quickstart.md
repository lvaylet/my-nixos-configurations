# Quickstart & Validation Guide: Local Development and Deployment Stack on Homelab

**Feature**: `029-homelab-dev-stack`
**Date**: 2026-10-26

## Prerequisites

- Repository checked out on a dedicated feature branch (`029-homelab-dev-stack`).
- Access to a Nix environment with flakes enabled.

## 1. Verify Configuration Evaluation

Verify that `homelab`, `desktop-pc`, and `macbook-air-m4-15` enable `direnv` (`nix-direnv`) and include the development stack, and that `homelab` preserves `.local/share/direnv`:

**Bash / Fish**:
```bash
nix eval .#nixosConfigurations.homelab.config.programs.direnv.enable
nix eval .#nixosConfigurations.homelab.config.programs.direnv.nix-direnv.enable
nix eval .#nixosConfigurations.desktop-pc.config.programs.direnv.enable
nix eval .#darwinConfigurations.macbook-air-m4-15.config.programs.direnv.enable
```
Expected output for each command: `true`.

## 2. Run Quality Gates

**Bash / Fish**:
```bash
just fmt
just lint
just check
```
*(If running on `homelab` before the new generation is activated, run via `nix develop -c just check` or `nix flake check`.)*

## 3. Bootstrap / Activate on `homelab`

For the initial activation on `homelab` before `just` is in the live system profile:

**Bash / Fish**:
```bash
sudo nixos-rebuild switch --flake .#homelab
```

Once activated on `homelab`, all subsequent deployments and checks use `just` directly:

**Bash / Fish**:
```bash
just --list
just test
just switch
```

## 4. Authorize Direnv in the Workspace on `homelab`

Navigate to the repository on `homelab` and authorize `.envrc` once:

**Bash / Fish**:
```bash
cd ~/workspace/github.com/lvaylet/my-nixos-configurations
direnv allow
```

Expected outcome:
- `direnv` loads `.envrc` (`use flake`) via `nix-direnv`, caching the `devShells.default` environment and installing the `pre-commit` Git hook.
- Across subsequent shell sessions and host reboots, entering the directory automatically activates the flake development environment without re-running `direnv allow`.
