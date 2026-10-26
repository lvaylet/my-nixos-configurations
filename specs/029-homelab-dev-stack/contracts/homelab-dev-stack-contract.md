# Contract: Homelab Local Development and Deployment Stack

**Feature**: `029-homelab-dev-stack`
**Date**: 2026-10-26

## 1. Host Configuration Evaluation Contract

### `nixosConfigurations.homelab`
- `config.programs.direnv.enable` MUST evaluate to `true`.
- `config.programs.direnv.nix-direnv.enable` MUST evaluate to `true`.
- `config.programs.direnv.enableFishIntegration` MUST evaluate to `true`.
- `config.programs.direnv.enableBashIntegration` MUST evaluate to `true`.
- `config.environment.systemPackages` MUST include `just`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `just-lsp`, `cachix`, `direnv`, and `nix-direnv`.
- `config.preservation.preserveAt."/persistent".users.laurent.directories` MUST include an entry for `".local/share/direnv"`.
- `config.systemd.services.opencode-web.path` MUST include `"/run/wrappers"`, `"/run/current-system/sw"`, and the core CLI tools (`bash`, `just`, `nh`, `direnv`, `nix`, `git`, `gh`, `ripgrep`, `coreutils`).

### `nixosConfigurations.desktop-pc` & `darwinConfigurations.macbook-air-m4-15`
- `config.programs.direnv.enable` MUST evaluate to `true`.
- `config.programs.direnv.nix-direnv.enable` MUST evaluate to `true`.
- `config.environment.systemPackages` MUST include `just`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `just-lsp`, and `cachix`.
- `config.home-manager.users.laurent.programs.direnv.enable` MUST evaluate to `false` (avoiding duplicate shell hooks with system-level `programs.direnv`).

## 2. Operational CLI Contract on `homelab`

From an interactive shell (Fish or Bash) or within an OpenCode session on `homelab` inside the repository root:

| Command | Expected Behavior |
|---------|-------------------|
| `just --list` | Lists all recipes from `justfile` with exit code `0`. |
| `just fmt` | Runs `nix fmt .` (`alejandra`) with exit code `0`. |
| `just lint` | Runs `deadnix` and `statix check` with exit code `0`. |
| `just check` | Runs `nix flake check` (all pre-commit hooks in sandbox) with exit code `0`. |
| `just test` | Auto-detects `homelab` hostname and runs `nh os test .#homelab` locally. |
| `just switch` | Auto-detects `homelab` hostname and runs `nh os switch .#homelab` locally. |
| `direnv allow` | Authorizes `.envrc` (`use flake`), activates `devShells.default`, and persists authorization in `~/.local/share/direnv`. |
