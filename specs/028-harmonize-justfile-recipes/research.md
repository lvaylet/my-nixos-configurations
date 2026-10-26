# Phase 0 Research: Harmonize Task Runner (`justfile`) Recipes and Syntax Across Hosts

**Feature**: `028-harmonize-justfile-recipes`
**Date**: 2026-10-26
**Spec**: [`specs/028-harmonize-justfile-recipes/spec.md`](./spec.md)

## Research Decisions

### 1. Recipe Naming & Taxonomy across All Managed Hosts

- **Decision**: Adopt a single unified set of parameterized lifecycle recipes under `[group('(re)build')]`:
  - `build configuration="" target=""`
  - `test configuration="" target=""`
  - `switch configuration="" target=""`
  - `boot configuration="" target=""`
  - `install target configuration="homelab"`
  - `build-iso`
  Remove legacy host-suffixed and divergent recipes (`build-darwin`, `test-darwin`, `switch-darwin`, `deploy-homelab`, `test-homelab`, `install-homelab`).
- **Rationale**:
  - Eliminates conflicting action verbs (`deploy-homelab` vs `switch` vs `switch-darwin`) and missing verb coverage (`build-homelab` and `boot-homelab` did not exist).
  - Reduces cognitive load: an operator always types `just build`, `just test`, `just switch`, `just boot`, or `just install` regardless of the host.
- **Alternatives Considered**:
  - *Per-machine suffixed recipes (`*-desktop`, `*-homelab`, `*-darwin`)*: Rejected because it multiplies recipes (`3 × 4 = 12` recipes) and duplicates shell logic across hosts.
  - *Hybrid generic + suffixed shortcuts*: Rejected by user preference in favor of Option A (pure unified parameterized recipes).

### 2. Automatic Host (`configuration`) & Remote Target (`target`) Resolution

- **Decision**:
  - **Default `configuration` resolution (when `configuration == ""`)**:
    1. If `uname -s == "Darwin"`, set `CONFIG="macbook-air-m4-15"`.
    2. Else on Linux, check `hostname -s` (or `uname -n`); if it matches `"homelab"` or `"desktop-pc"`, set `CONFIG` to that hostname; otherwise default to `"desktop-pc"`.
  - **Smart `target` resolution (when `target == ""` on NixOS lifecycle actions `test`, `switch`, `boot`)**:
    1. If `CONFIG` is a NixOS host (`desktop-pc` or `homelab`) and either the local machine is not NixOS (`! -e /etc/NIXOS`) or its local hostname (`hostname -s`) differs from `CONFIG`, automatically set `TARGET="${CONFIG}"`.
    2. For `build`, keep `TARGET=""` unless explicitly passed so `just build homelab` compiles the derivation locally without requiring SSH access to `homelab`.
- **Rationale**:
  - Running `just test` or `just switch` with zero arguments on `macbook-air-m4-15`, `desktop-pc`, or `homelab` immediately targets the local machine.
  - Running `just test homelab` or `just switch homelab` from `desktop-pc` (or from a non-NixOS Linux workstation) automatically deploys over SSH to `homelab` without requiring redundant repetition (`just switch homelab homelab`), while still allowing `just switch homelab 192.168.1.180` if a custom IP/host is desired.
- **Alternatives Considered**:
  - *Hardcoded `configuration="desktop-pc"` default*: Rejected because running `just switch` on `macbook-air-m4-15` or `homelab` without arguments would target the wrong machine.
  - *Failing when `target=""` and `hostname != configuration`*: Rejected because inferring `TARGET="${CONFIG}"` is safer and more ergonomic than attempting to apply `homelab`'s closure to `desktop-pc`.

### 3. Unified Privilege Elevation & Remote SSH Strategy (`sudo` / `--use-remote-sudo`)

- **Decision**:
  - **NixOS Remote (`target` non-empty)**: Connect as the current SSH user (`laurent`, configured via `modules/services/ssh.nix` and Tailscale SSH) with passwordless `sudo` (`security.sudo.wheelNeedsPassword = false` in `modules/core/base.nix`):
    - If `nh` is available: `nh os <build|test|switch|boot> .#"${CONFIG}" --elevation-strategy passwordless --target-host "${TARGET}"` (or `nh os build .#"${CONFIG}" --target-host "${TARGET}"` for `build`).
    - Fallback without `nh`: `nixos-rebuild <test|switch|boot> --flake .#"${CONFIG}" --target-host "${TARGET}" --use-remote-sudo` (and `nixos-rebuild build --flake .#"${CONFIG}" --target-host "${TARGET}"` for `build`).
  - **NixOS Local (`target` empty on matching NixOS host)**:
    - If `nh` is available: `nh os <build|test|switch|boot> .#"${CONFIG}"`.
    - Fallback without `nh`: `sudo nixos-rebuild <test|switch|boot> --flake .#"${CONFIG}"` (and `nix build .#nixosConfigurations."${CONFIG}".config.system.build.toplevel` for `build`).
  - **Darwin (`macbook-air-m4-15`)**:
    - `build`: `nix build .#darwinConfigurations."${CONFIG}".system` (or `nh darwin build .#"${CONFIG}"` if desired, keeping `nix build` for deterministic `result` symlink).
    - `test`: Verify `uname -s == "Darwin"`, build system path via `nix build --no-link --print-out-paths .#darwinConfigurations."${CONFIG}".system`, then execute `sudo "${systemConfig}/activate"`.
    - `switch`: Verify `uname -s == "Darwin"`, then execute `sudo nix run nix-darwin -- switch --flake .#"${CONFIG}"`.
    - `boot` / `install`: Exit with an explicit error explaining that `boot` and `install` apply only to NixOS configurations.
  - **Initial Bare-Metal Bootstrap (`just install target configuration="homelab"`)**:
    - Prepend `root@` if `target` does not contain `@` (since the custom NixOS installer ISO expects `root@` for disk partitioning via `disko`), and invoke `nix run github:nix-community/nixos-anywhere -- --flake .#"${CONFIG}" "${TARGET_HOST}"`.
- **Rationale**:
  - Works across all 3 hosts (`homelab`, `desktop-pc`, `macbook-air-m4-15`): `desktop-pc` sets `PermitRootLogin = "no"`, so `root@` fails on `desktop-pc`, whereas `laurent` has SSH key authorization and `wheelNeedsPassword = false` on both `desktop-pc` and `homelab`.
  - On macOS (`macbook-air-m4-15`), `nix-darwin` activation requires `sudo` (with Touch ID enabled in `modules/core/base.nix` via `security.pam.services.sudo_local.touchIdAuth = true`).
  - `nh` 4.4.2 supports `--elevation-strategy passwordless` for remote hosts with `NOPASSWD` configured, avoiding interactive TTY issues over SSH while providing rich diff and nix-output-monitor trees.
- **Alternatives Considered**:
  - *Forcing `root@` on all remote targets*: Rejected because `desktop-pc` disables root SSH login (`PermitRootLogin = "no"`).
