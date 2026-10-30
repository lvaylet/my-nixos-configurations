# Implementation Plan: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Branch**: `027-refactor-core-modules` | **Date**: 2026-10-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/027-refactor-core-modules/spec.md`

## Summary

Resolve GitHub Issue #36 by:

1. Replacing the hardcoded `"laurent"` username in `modules/services/ssh.nix` with `vars.userName`.
2. Decoupling bootloader configurations from `modules/core/base.nix` into modular core features (`core.limine` and `core.grub` in `modules/core/bootloader.nix`), enabling `core.limine` on `desktop-pc` and `core.grub` on `homelab` without `lib.mkForce` overrides.
3. Deduplicating the ~42 Git shell aliases across NixOS and Darwin in `modules/core/base.nix` via shared `let` bindings (`systemdAliases`, `gitAliases`) and adopting native `programs.fish.shellAbbrs` on both platforms to replace ~45 lines of manual `complete -c` wrapper commands.
4. Synchronizing `README.md` with the modular bootloader structure and native Fish abbreviations.

## Technical Context

**Language/Version**: Nix (Flakes, NixOS 26.05, nix-darwin, Home Manager 26.05)

**Primary Dependencies**: `nixpkgs` (`nixos-unstable`), `flake-parts`, `import-tree`, `home-manager`, `nix-darwin`

**Storage**: N/A (declarative Nix configuration modules)

**Testing**: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`), `just check` (`nix flake check`), `nix eval`

**Target Platform**: `x86_64-linux` (`desktop-pc`, `homelab`, `iso`) and `aarch64-darwin` (`macbook-air-m4-15`)

**Project Type**: Declarative multi-host NixOS / nix-darwin / Home Manager flake repository

**Performance Goals**: Zero redundant manual `complete -c` invocations on interactive Fish startup; zero duplicate alias definitions across platforms

**Constraints**: Must adhere strictly to the Dendritic Pattern (`import-tree ./modules`), pass all pre-commit hooks hermetically, and preserve dual-shell (Bash & Fish) parity

**Scale/Scope**: 5 repository files modified/created (`modules/core/bootloader.nix`, `modules/core/base.nix`, `modules/services/ssh.nix`, `modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`, `README.md`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: PASS — All changes are purely declarative NixOS, nix-darwin, and Home Manager modules with no lockfile or imperative modifications.
- **II. Dendritic Modularity & Feature-Centric Composition**: PASS — Bootloaders are extracted into `modules/core/bootloader.nix` (`core.limine`, `core.grub`), host files compose features without inline bootloader overrides, and `modules/services/ssh.nix` consumes `vars.userName` from `config.flake.vars`.
- **III. Shift-Left Quality, Formatting & Static Analysis**: PASS — All modified and added `.nix` and `.md` files will be validated with `just fmt`, `just lint`, and `just check`.
- **IV. Zero-Secrets Leakage & Security First**: PASS — No secrets or credentials introduced.
- **V. Rigorous Verification & Safe Deployment Workflow**: PASS — Evaluated across all flake targets (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`) and checked via `just check`.
- **VI. Living Documentation & Dual-Shell Parity**: PASS — `README.md` updated to document `programs.fish.shellAbbrs` and modular bootloaders while preserving `environment.shellAliases` for Bash parity.
- **VII. Dedicated Branch & Pull Request Workflow**: PASS — All work is isolated on branch `027-refactor-core-modules` and submitted via a dedicated Pull Request.

## Project Structure

### Documentation (this feature)

```text
specs/027-refactor-core-modules/
├── spec.md              # Feature specification
├── plan.md              # Implementation plan
├── research.md          # Technical decisions and rationale
├── data-model.md        # Module and configuration entity definitions
├── quickstart.md        # Verification commands and expected outputs
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Dependency-ordered implementation tasks
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix         # Shared systemdAliases/gitAliases let-bindings, programs.fish.shellAbbrs, bootloader removed
│   └── bootloader.nix   # New modular bootloader features: flake.modules.core.limine & flake.modules.core.grub
├── services/
│   └── ssh.nix          # Uses vars.userName in Home Manager programs.ssh.settings.homelab
└── hosts/
    ├── desktop-pc.nix   # Adds core.limine to features
    └── homelab.nix      # Adds core.grub to features, removes inline boot.loader and unused lib arg
README.md                # Updated documentation for shellAbbrs and modular bootloaders
```

**Structure Decision**: Follows the existing Dendritic Pattern under `modules/core/`, `modules/services/`, and `modules/hosts/`, where `modules/core/bootloader.nix` is automatically discovered by `inputs.import-tree ./modules`.

## Complexity Tracking

No constitution violations.
