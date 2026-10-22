# Implementation Plan: Integrate MacBook Air M4 Host and Mutualize Shared Configurations

**Branch**: `021-integrate-macbook-air` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/021-integrate-macbook-air/spec.md`

## Summary

Integrate the newly acquired MacBook Air M4 (`macbook-air-m4-15`) running macOS (`aarch64-darwin`) into the repository's dendritic configuration architecture. Maximum reuse of existing workstation and homelab features is achieved by:

1. Adding `nix-darwin` to `flake.nix` and creating a symmetrical `mkDarwinHost` builder in `modules/core/lib.nix`.
2. Slicing dendritic feature modules cleanly into `nixos`, `darwin`, and `homeManager` keys, allowing 100% of portable user environments (`desktop.shell`, `core.git`, `core.neovim`, `desktop.editors`, `desktop.terminal`, `desktop.apps`, and `services.ssh` client alias) to be shared with `desktop-pc` without code duplication.
3. Guarding platform-specific packages and options (e.g. `wl-clipboard`, `fonts.fontconfig`, Linux disk partitioning tools) with `pkgs.stdenv.isLinux` so shared modules evaluate cleanly on both Linux and Darwin.
4. Keeping Linux-specific infrastructure (Niri compositor, Noctalia shell, PipeWire, Nvidia GPU, homelab server daemons) strictly confined to their host environments.
5. Providing full living documentation in `README.md` with dual Bash and Fish command instructions.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `nixpkgs` (unstable)
- `nix-darwin` (`github:LnL7/nix-darwin`)
- `home-manager` (`github:nix-community/home-manager`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)

**Storage**:

- User configuration and dotfiles: `~/.config/` via Home Manager symlinks to `/nix/store`
- System profile: `/run/current-system` managed by `nix-darwin`
- Applications: `/Applications/Nix Apps` managed by `nix-darwin`

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake checks: `just check` (`nix flake check`)
- Host evaluation:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#darwinConfigurations.macbook-air-m4-15.system.drvPath`

**Target Platform**: Multi-target workstation infrastructure:

- macOS (`aarch64-darwin`) for `macbook-air-m4-15`
- NixOS (`x86_64-linux`) for `desktop-pc` and `homelab`

**Project Type**: Infrastructure as Code / Nix Multi-Host Configuration (Dendritic Pattern)

**Performance Goals**:

- Clean hermetic evaluation of all flake outputs in < 15 seconds
- Immediate zero-configuration shell environment on first launch on `macbook-air-m4-15`

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/macbook-air-m4-15.nix` contains zero inline service or environment definitions.
- Zero duplication of shell, prompt, editor, or git configuration files.
- `homelab` retains its existing headless configuration and server services.
- `README.md` updated within the same branch with dual Bash and Fish command parity.

**Scale/Scope**:

- 1 updated root file: `flake.nix` (add `darwin` input)
- 1 updated builder file: `modules/core/lib.nix` (add `mkDarwinHost`)
- 1 new host definition: `modules/hosts/macbook-air-m4-15.nix`
- 6 updated feature modules: `modules/core/base.nix`, `modules/core/neovim.nix`, `modules/desktop/editors.nix`, `modules/desktop/fonts.nix`, `modules/desktop/terminal.nix`, `modules/desktop/apps.nix`
- 1 updated task runner: `justfile` (add Darwin switch/build recipe)
- 1 updated documentation: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative `$HOME` drift | **PASS** | `nix-darwin` and `home-manager` manage macOS system and user configurations hermetically via pinned flake inputs. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services | **PASS** | Modules export `nixos`, `darwin`, and `homeManager` keys cleanly. `modules/hosts/macbook-air-m4-15.nix` only composes enabled features. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | All new and modified Nix expressions pass `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials, SSH public keys only in repo | **PASS** | Only public keys from `core.vars` are used. No private keys or tokens committed. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and evaluation before switching | **PASS** | Evaluation of `darwinConfigurations.macbook-air-m4-15` verified prior to activation. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` documents `macbook-air-m4-15` host inventory, architecture, and setup commands in both Bash and Fish. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | Feature isolated on branch `021-integrate-macbook-air`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/021-integrate-macbook-air/
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Technical research & architectural decisions
├── data-model.md        # Entities, attributes, and relationships
├── quickstart.md        # Validation procedures and runnable scenarios
├── contracts/           # Structural contracts
│   ├── darwin-host-contract.md
│   └── shared-features-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
flake.nix                          # Add `darwin` input
modules/
├── core/
│   ├── lib.nix                    # Introduce `mkDarwinHost` builder
│   ├── base.nix                   # Add `darwin` system settings (trusted users, touch ID)
│   ├── neovim.nix                 # Cross-platform Neovim config & dotfile linking
│   └── vars.nix                   # Shared identity variables (reused)
├── desktop/
│   ├── apps.nix                   # Guard Linux-only partition tools with isLinux
│   ├── editors.nix                # Guard wl-clipboard with isLinux
│   ├── fonts.nix                  # Guard fontconfig with isLinux
│   ├── shell.nix                  # Pure Home Manager fish/starship (shared as-is)
│   └── terminal.nix               # Guard wayland toggle with isLinux
├── services/
│   └── ssh.nix                    # Client SSH alias to homelab (shared as-is)
└── hosts/
    ├── desktop-pc.nix             # Unchanged (NixOS workstation)
    ├── homelab.nix                # Unchanged (NixOS server)
    └── macbook-air-m4-15.nix      # New declarative Darwin host definition
justfile                           # Darwin rebuild recipes
README.md                          # Documentation and dual-shell commands
```
