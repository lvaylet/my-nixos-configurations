# Research: Local Development and Deployment Stack on Homelab

**Feature**: `029-homelab-dev-stack`
**Date**: 2026-10-26

## 1. Root Cause Analysis: Why `just` and the Local Dev Stack Are Missing on `homelab`

### Findings
- On workstations (`desktop-pc` and `macbook-air-m4-15`), the Nix development and deployment stack (`just`, `just-lsp`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `cachix`) and `programs.direnv` (`enable = true`, `nix-direnv.enable = true`) were declared inside `modules/desktop/apps.nix` under `homeManager`.
- On `homelab` (`modules/hosts/homelab.nix`), `enableHomeManager = false` and `desktop.apps` is not enabled because `homelab` is a headless server.
- Consequently, `homelab` only received the minimal `environment.systemPackages` from `modules/core/base.nix` (`curl`, `gh`, `git`, `htop`, `wget`), lacking `just`, `nh`, `direnv`, and the Nix linter/formatter tools.
- Furthermore, `systemd.services.opencode-web` in `modules/services/opencode.nix` defines a restricted `path` (`[ git ripgrep coreutils ]`), which omits `bash`, `nix`, `just`, `nh`, `direnv`, `/run/wrappers` (`sudo`), and `/run/current-system/sw` (system profile binaries).

## 2. Environment Activation Strategy: `direnv` + `nix-direnv` vs. `devbox`

### Decision
Enable `programs.direnv` with `nix-direnv.enable = true` at the system level in `modules/core/base.nix` (across both `nixos` and `darwin` targets), and provide the core Nix development and deployment CLI tools in `core.base` `environment.systemPackages`.

### Rationale
- The repository root already contains `.envrc` with `use flake`, which activates `devShells.default` defined in `modules/core/devshell.nix` (`just`, `nh`, `alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`, and automatic `pre-commit` hook installation).
- Both NixOS and `nix-darwin` natively provide `programs.direnv.enable` and `programs.direnv.nix-direnv.enable`. When enabled alongside `programs.fish.enable = true` in `core.base`, `direnv` automatically hooks into both Bash and Fish interactive shells and caches evaluated flake devshells in `/nix/store` GC roots via `nix-direnv`.
- Installing `devbox` on a native NixOS host is redundant because `devbox.json` was introduced solely as a portable bootstrap wrapper for non-NixOS hosts (see `002-portable-dev-deploy`), whereas NixOS natively evaluates `flake.nix` via `direnv` (`use flake`).
- Centralizing `programs.direnv` and the Nix CLI stack (`just`, `just-lsp`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `cachix`) in `core.base` (and removing their duplicate definitions from `desktop.apps`) ensures every host (`desktop-pc`, `homelab`, `macbook-air-m4-15`) shares the exact same baseline Nix tooling without double-registering `direnv` shell hooks between NixOS/Darwin and Home Manager.

### Alternatives Considered
- **Install `devbox` on `homelab`**: Rejected because `devbox` wraps Nix packages for non-NixOS distributions; on NixOS, `direnv` + `nix-direnv` + `.envrc` (`use flake`) natively activates `devShells.default` and installs `git-hooks.nix` pre-commit hooks.
- **Enable Home Manager and `desktop.apps` on `homelab`**: Rejected because `desktop.apps` pulls in GUI applications (`google-chrome`, `ghostty`, `obsidian`, `tparted`) and `libinput`, which violate `homelab`'s headless server design (`enableHomeManager = false`).
- **Rely solely on `direnv` without global `just` / `nh` in `core.base`**: Rejected because operators or non-interactive processes (such as `opencode-web` or running `just` before `direnv allow`) need `just`, `nh`, `alejandra`, `deadnix`, and `statix` immediately available in `PATH`.

## 3. Ephemeral Root Persistence for `direnv` on `homelab`

### Decision
Add `".local/share/direnv"` to `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/core/preservation.nix`.

### Rationale
- `homelab` uses an ephemeral `tmpfs` root filesystem managed by `preservation.nix`.
- By default following the XDG Base Directory specification, `direnv` stores trusted `.envrc` hashes under `~/.local/share/direnv/allow`.
- Preserving `.local/share/direnv` ensures that running `direnv allow` in `/home/laurent/workspace/github.com/lvaylet/my-nixos-configurations` persists across host reboots.

### Alternatives Considered
- **Use `programs.direnv.settings.whitelist`**: Rejected because declarative whitelisting in `/etc/direnv/direnv.toml` is less flexible for ad-hoc workspaces under `~/workspace` than preserving `~/.local/share/direnv` directly.

## 4. OpenCode Web Service (`opencode-web`) Execution Environment on `homelab`

### Decision
Expand `systemd.services.opencode-web.path` in `modules/services/opencode.nix` to include `"/run/wrappers"`, `"/run/current-system/sw"`, and core development/deployment packages (`bash`, `coreutils`, `direnv`, `git`, `gh`, `just`, `nh`, `nix`, `nixos-rebuild`, `openssh`, `ripgrep`).

### Rationale
- `systemd.services.opencode-web` runs non-interactively and does not source interactive shell profiles (`/etc/profile`) or `/run/wrappers/bin` by default.
- Adding `"/run/wrappers"` (which provides setuid `sudo`) and `"/run/current-system/sw"` (which exposes all `environment.systemPackages`) alongside explicit core packages ensures that OpenCode web sessions on `homelab` can run `just check`, `just test`, `just switch`, `just fmt`, `just lint`, and `.specify/scripts/bash/*` scripts cleanly.

### Alternatives Considered
- **Keep minimal `path = [ git ripgrep coreutils ]`**: Rejected because OpenCode sessions on `homelab` fail with `env: ‘bash’: No such file or directory` or `just: command not found` when attempting to run repository workflows or deploy configurations.
