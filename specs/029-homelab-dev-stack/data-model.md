# Data Model: Local Development and Deployment Stack on Homelab

**Feature**: `029-homelab-dev-stack`
**Date**: 2026-10-26

## Entities & Configuration Modules

### 1. Shared Core Development & Deployment Stack (`modules/core/base.nix`)

| Attribute / Option | Platform Scope | Value / Contents | Purpose |
|--------------------|----------------|------------------|---------|
| `programs.direnv.enable` | `nixos`, `darwin` | `true` | Enables system-wide `direnv` and automatic Bash/Fish shell integration (`enableBashIntegration = true`, `enableFishIntegration = true`). |
| `programs.direnv.nix-direnv.enable` | `nixos`, `darwin` | `true` | Enables fast, persistent caching of `use flake` / `use nix` environments via `nix-direnv`. |
| `environment.systemPackages` (Nix Stack) | `nixos`, `darwin` | `alejandra`, `cachix`, `deadnix`, `just`, `just-lsp`, `nh`, `nixd`, `statix` | Provides the task runner, deployment helper, Nix formatter/linters, and language servers across all hosts (`homelab`, `desktop-pc`, `macbook-air-m4-15`). |

### 2. Desktop Applications Deduplication (`modules/desktop/apps.nix`)

| Attribute / Option | Platform Scope | Change | Purpose |
|--------------------|----------------|--------|---------|
| `home.packages` (Nix section) | `homeManager` | Removed (`alejandra`, `deadnix`, `nixd`, `statix`, `nh`, `cachix`, `just`, `just-lsp` moved to `core.base`) | Eliminates duplicate package declarations between `desktop.apps` and `core.base`. |
| `programs.direnv` | `homeManager` | Removed (moved to `core.base` `nixos` and `darwin`) | Prevents duplicate `direnv` shell hooks in Fish and Bash on `desktop-pc` and `macbook-air-m4-15`. |

### 3. Ephemeral Root State Preservation (`modules/core/preservation.nix`)

| Attribute / Option | Platform Scope | Value | Purpose |
|--------------------|----------------|-------|---------|
| `preservation.preserveAt."/persistent".users.${vars.userName}.directories` | `nixos` (`homelab`) | Added `".local/share/direnv"` | Persists `direnv allow` authorizations across reboots on ephemeral `tmpfs` root filesystems. |

### 4. OpenCode Web Daemon Execution Path (`modules/services/opencode.nix`)

| Attribute / Option | Platform Scope | Value | Purpose |
|--------------------|----------------|-------|---------|
| `systemd.services.opencode-web.path` | `nixos` (`homelab`) | `"/run/wrappers"`, `"/run/current-system/sw"`, plus `bash`, `coreutils`, `direnv`, `gh`, `git`, `just`, `nh`, `nix`, `nixos-rebuild`, `openssh`, `ripgrep` | Ensures `opencode-web` sessions on `homelab` can run `just`, `nh`, `sudo`, `bash`, `nix`, and git workflows without missing binary errors. |

## State Transitions (Direnv Environment Lifecycle on `homelab`)

1. **Unauthorized Workspace**: User clones or navigates to `/home/laurent/workspace/github.com/lvaylet/my-nixos-configurations`. Baseline system tools (`just`, `nh`, `direnv`, `alejandra`, `deadnix`, `statix`) are already available in `/run/current-system/sw/bin`.
2. **Authorized Workspace (`direnv allow`)**: User runs `direnv allow`. Authorization hash is written to `/home/laurent/.local/share/direnv/allow/` (persisted under `/persistent/home/laurent/.local/share/direnv`).
3. **Active Flake Devshell (`use flake`)**: `nix-direnv` evaluates `devShells.default` from `modules/core/devshell.nix`, caches the profile in `.direnv/flake-profile-*`, and runs the `git-hooks.nix` `shellHook` to install `.git/hooks/pre-commit`.
4. **Post-Reboot Continuity**: After `homelab` reboots, `/persistent/home/laurent/.local/share/direnv` and `/persistent/home/laurent/workspace` remain intact; entering the workspace in Fish or Bash immediately reloads the cached devshell without re-running `direnv allow`.
