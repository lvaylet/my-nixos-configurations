# Implementation Plan: Codebase Migration to the Dendritic Pattern

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-migrate-dendritic-pattern/spec.md`

## Summary

Migrate the entire NixOS configuration codebase to the **Dendritic Pattern** using **`flake-parts`** and **`denful/import-tree`**. This architecture inverts configuration control: every non-entrypoint Nix file is evaluated as a top-level module, and capabilities are organized into domain-grouped features under a unified `modules/` tree (`core/`, `desktop/`, `services/`, `hosts/`). Feature files colocate NixOS system configurations and Home Manager user environments side-by-side. Machine targets (`desktop-pc`, `homelab`, `iso`) are declared declaratively by specifying their hardware attributes and an explicit list of enabled features, eliminating fragile path imports and parameter pass-through boilerplate while preserving 100% functional parity and continuous integration quality gates.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)
- `home-manager` (`github:nix-community/home-manager`)
- `nvf` (`github:NotAShelf/nvf`)
- `noctalia` (`github:noctalia-dev/noctalia`)
- `git-hooks` (`github:cachix/git-hooks.nix`)

**Storage**: Declarative `/nix/store` immutable derivations, symlinked dotfiles under `~/.config/` via Home Manager.

**Testing**:
- Formatting & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Hermetic pre-commit sandboxes: `just check` (`nix flake check`).
- Target closure builds: `just build configuration="desktop-pc"`, `just build configuration="homelab"`, `just build-iso`.
- Non-destructive activation: `just test configuration="desktop-pc"`.

**Target Platform**: Multi-target Linux infrastructure (`desktop-pc` workstation, `homelab` server, `iso` minimal installer) plus cross-platform developer toolchains (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS modules, Home Manager modules).

**Performance Goals**:
- Flake evaluation duration within 10% of pre-migration baseline.
- Automated feature discovery with zero perceptible evaluation overhead.

**Constraints**:
- Atomic migration across all targets with zero functional regression.
- Adherence to repository constitution quality principles (I, III, IV, V).
- Principle II architecture evolved to ratify the dendritic paradigm via formal constitution amendment (v2.0.0).
- Zero plaintext secrets committed.

**Scale/Scope**: 3 target configurations (`desktop-pc`, `homelab`, `iso`), ~45 feature modules reorganized into 4 domains under `modules/`, 1 primary user (`laurent`).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, no imperative `$HOME` drift | **PASS** | Flake inputs pinned via `flake.lock`; all configurations remain purely declarative via Nix flakes and modules. |
| **II. Modular Separation & DRY** | Clean separation of concerns, DRY parameterization, zero inline duplication | **PASS (Evolved)** | Replaces legacy host-centric folder silos with feature-centric domain modules under `modules/`. Shared identity is centralized in `modules/core/vars.nix` via `config.flake.vars`. Constitution Principle II will be amended to v2.0.0 to ratify this architectural evolution. |
| **III. Shift-Left Quality** | Clean formatting (`alejandra`), zero `statix`/`deadnix` errors, clean `just check` | **PASS** | Hermetic pre-commit checks and static linters are wired into `perSystem` outputs in `modules/core/checks.nix` and `modules/core/formatter.nix`. |
| **IV. Zero Secrets Leakage** | No secrets in plaintext, automated secret detection passing | **PASS** | No credentials committed; secret detection filters remain active in git-hooks sandbox checks. |
| **V. Safe Deployment & Rollback** | `just check` -> `just test` -> `just switch`; generation rollback preserved | **PASS** | All operational recipes in `justfile` preserved with identical signatures and non-destructive activation guarantees. |

---

## Project Structure

### Documentation (this feature)

```text
specs/005-migrate-dendritic-pattern/
├── plan.md              # Implementation Plan (/speckit.plan command output)
├── research.md          # Technical research and design decisions (Phase 0)
├── data-model.md        # Entities, attributes, and relationships (Phase 1)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   ├── flake-outputs-contract.md
│   ├── feature-module-contract.md
│   └── host-composition-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
flake.nix                               # Root entrypoint invoking mkFlake and import-tree ./modules
modules/
├── core/                               # Flake-level outputs, options, base system, checks, devshell
│   ├── systems.nix                     # Multi-system target list
│   ├── vars.nix                        # Centralized identity options (config.flake.vars)
│   ├── lib.nix                         # mkHost helper builder
│   ├── base.nix                        # Core base system configuration
│   ├── devshell.nix                    # Multi-system devShells.default
│   ├── checks.nix                      # Multi-system pre-commit checks
│   └── formatter.nix                   # Multi-system formatter wrapper
├── desktop/                            # Workstation graphical capabilities & tools
│   ├── session.nix                     # Niri compositor + Noctalia desktop shell + Greetd
│   ├── terminal.nix                    # WezTerm configuration & ligatures
│   ├── shell.nix                       # Fish shell & Starship prompt
│   ├── fonts.nix                       # FiraCode Nerd Font & typography
│   ├── editors.nix                     # Neovim (nvf), VS Code, Zed editor
│   ├── audio.nix                       # Pipewire audio configuration
│   ├── graphics.nix                    # Nvidia GPU acceleration & Prime
│   └── apps.nix                        # Desktop GUI applications
├── services/                           # Server daemons, network, storage, virtualization
│   ├── network.nix                     # NetworkManager & firewall
│   ├── ssh.nix                         # OpenSSH daemon & client configuration
│   ├── tailscale.nix                   # Tailscale VPN mesh
│   ├── podman.nix                      # Podman container runtime
│   ├── media.nix                       # Shared media storage directories & permissions
│   ├── jellyfin.nix                    # Jellyfin media server daemon
│   ├── qbittorrent.nix                 # Headless torrent service
│   ├── filebrowser.nix                 # Web file manager daemon
│   ├── adguardhome.nix                 # AdGuard Home DNS sinkhole
│   ├── home-automation.nix             # Home automation services
│   ├── printing.nix                    # CUPS printing service
│   ├── ssd.nix                         # Periodic SSD trim service
│   └── virtualization.nix              # VMware Workstation & hypervisor tools
└── hosts/                              # Concrete machine target definitions
    ├── hardware/                       # Isolated machine hardware specifications
    │   ├── desktop-pc.nix              # Desktop PC hardware configuration
    │   └── homelab.nix                 # Homelab server hardware configuration
    ├── desktop-pc.nix                  # Workstation closure (composition of features)
    ├── homelab.nix                     # Homelab closure (composition of features)
    └── iso.nix                         # Bootable installer ISO closure
```

**Structure Decision**:
Consolidate the legacy `machines/`, `modules/nixos/`, and `modules/home-manager/` directories into a single `modules/` tree structured around functional domains (`core/`, `desktop/`, `services/`, `hosts/`). This enables a single `(import-tree ./modules)` call in `flake.nix` while grouping features by practical business capability.

---

## Complexity Tracking

| Violation / Architectural Evolution | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| **Evolving Constitution Principle II from directory silos (`machines/`, `modules/nixos/`, `modules/home-manager/`) to dendritic domain modules (`modules/<domain>/`)** | Eliminates duplicate feature files across system and user boundaries, enabling single-file feature ownership and automated module discovery. | Keeping directory silos requires manual import arrays and prevents colocating NixOS and Home Manager settings for the same capability. |
| **Introducing `flake-parts` and `import-tree` as inputs** | Provides battle-tested multi-system flake output management and automated recursive directory crawling without boilerplate. | Manual `builtins.readDir` crawling requires brittle custom code and lacks standard community support. |
| **Centralizing `vars` as a top-level module option** | Eliminates manual plumbing of `specialArgs` and `extraSpecialArgs` across module invocations. | Directly importing `vars.nix` in every file couples modules to fixed filesystem paths. |
