# Implementation Plan: Desktop Environment Migration to Niri and Noctalia (NNN Stack)

**Branch**: `feat-migrate-to-niri-and-noctalia` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-switch-to-niri-noctalia/spec.md`

## Summary

Migrate the primary workstation (`desktop-pc`) from the COSMIC desktop environment to the modern NNN stack (NixOS + Niri + Noctalia). This transition replaces the COSMIC desktop manager and greeter with the native Niri scrollable-tiling Wayland compositor and the unified Noctalia desktop shell (bar, launcher, notifications, lockscreen), authenticated through Greetd with Tuigreet. Daily developer ergonomics are elevated with WezTerm as the primary GPU-accelerated terminal emulator, Fish as the interactive shell, and FiraCode Nerd Font with active typographical ligatures configured across WezTerm and Neovim (`nvf`).

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua 5.4 (WezTerm configuration), Fish shell script, KDL (Niri configuration), TOML (Noctalia configuration)

**Primary Dependencies**:
- NixOS `programs.niri` (Wayland compositor)
- Noctalia (`github:noctalia-dev/noctalia` via Flake input)
- `greetd` + `tuigreet` (Wayland KMS login greeter)
- `programs.wezterm` (Home Manager terminal emulator)
- `programs.fish` (NixOS system integration & Home Manager user configuration)
- `nvf` (Neovim Flake module)
- `nerd-fonts.fira-code` (Font with ligatures & glyphs)

**Storage**: Declarative `/nix/store` immutable derivations, symlinked user configuration files under `~/.config/` via Home Manager.

**Testing**:
- Local static analysis and formatting: `just fmt`, `just lint` (`statix`, `deadnix`)
- Pre-commit sandbox checks: `just check` (`nix flake check`)
- Top-level closure build dry-run: `nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel --no-link`
- Non-destructive live test activation: `just test configuration="desktop-pc"`

**Target Platform**: Linux x86_64 workstation (`desktop-pc`, NixOS 26.05 unstable, Nvidia GPU).

**Project Type**: Declarative NixOS system and Home Manager user configuration.

**Performance Goals**:
- Graphical session boot to responsive interactive state in < 5 seconds.
- Interactive Fish terminal prompt rendering in < 50 milliseconds.
- Wayland compositor animation and window scrolling at native display refresh rate (60+ FPS) without stutter.

**Constraints**:
- Absolute adherence to project constitution (Principles I through V).
- Zero plaintext secrets committed.
- Clean retirement of all COSMIC services (zero orphan background daemons).
- Full preservation of POSIX compatibility for system and CI scripting.

**Scale/Scope**: 1 physical workstation machine (`desktop-pc`), 1 primary user (`laurent`), modular NixOS and Home Manager components.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, no imperative `$HOME` drift | **PASS** | Noctalia added as pinned flake input; all configurations declared in NixOS and Home Manager modules. |
| **II. Modular Separation & DRY** | Clean separation: `machines/`, `modules/nixos/`, `modules/home-manager/` | **PASS** | Compositor & greeter in `modules/nixos/desktop.nix`; shell, terminal, and desktop shell in `modules/home-manager/`; host imports in `machines/desktop-pc/`. |
| **III. Shift-Left Quality** | Clean formatting (`alejandra`), zero `statix`/`deadnix` errors, clean `just check` | **PASS** | Quality gates strictly incorporated in validation workflow and CI pipeline. |
| **IV. Zero Secrets Leakage** | No secrets in plaintext, automated secret detection passing | **PASS** | No credentials or private keys involved in desktop/terminal configuration. |
| **V. Safe Deployment & Rollback** | `just check` -> `just test` -> `just switch`; generation rollback preserved | **PASS** | Non-switching `just test` validation mandated prior to profile activation; prior COSMIC generation preserved in Limine bootloader. |

---

## Project Structure

### Documentation (this feature)

```text
specs/004-switch-to-niri-noctalia/
├── plan.md              # Implementation Plan (/speckit.plan command output)
├── research.md          # Technical research and design decisions (Phase 0)
├── data-model.md        # Entities, attributes, and relationships (Phase 1)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1)
├── contracts/           # Module and keybinding interface contracts (Phase 1)
│   ├── desktop-module-contract.md
│   └── keybindings-ipc-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
flake.nix                               # Declare upstream noctalia input
machines/desktop-pc/
└── configuration.nix                   # Update imports (swap cosmic for niri, wezterm, fish, noctalia)
modules/nixos/
└── desktop.nix                         # Enable Niri & Greetd (tuigreet); remove COSMIC services
modules/home-manager/
├── niri.nix                            # User Niri compositor settings, autostart & keybindings
├── noctalia.nix                        # User Noctalia desktop shell integration & theme
├── wezterm.nix                         # User WezTerm terminal configuration & ligatures
├── fish.nix                            # User Fish interactive shell settings & Starship prompt
├── fonts.nix                           # Ensure FiraCode Nerd Font is installed
├── dotfiles/
│   └── niri/
│       └── config.kdl                  # Declarative static KDL configuration for Niri
└── base.nix                            # Reference fish shell if appropriate
```

**Structure Decision**:
Follows the repository's established architecture (Constitution Article II):
- Machine entrypoint (`machines/desktop-pc/configuration.nix`) remains an assembler.
- Reusable system services reside in `modules/nixos/`.
- User tools, shell, and typography reside in `modules/home-manager/`.
- Static dotfiles reside under `modules/home-manager/dotfiles/`.

---

## Complexity Tracking

*No constitutional violations identified. No complexity justifications required.*
