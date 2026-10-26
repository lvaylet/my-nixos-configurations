# Implementation Plan: Local Development and Deployment Stack on Homelab

**Branch**: `029-homelab-dev-stack` | **Date**: 2026-10-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/029-homelab-dev-stack/spec.md`

## Summary

Enable local development, verification, and self-deployment directly on `homelab` by promoting `programs.direnv` (with `nix-direnv`) and the core Nix development and deployment CLI stack (`just`, `just-lsp`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `cachix`) from `modules/desktop/apps.nix` into the shared base module `modules/core/base.nix` (`nixos` and `darwin`). Additionally, persist `~/.local/share/direnv` across reboots on ephemeral-root hosts (`modules/core/preservation.nix`), expand the `opencode-web` systemd service `path` (`modules/services/opencode.nix`) so self-hosted OpenCode sessions on `homelab` can run `just`, `nh`, `sudo`, `bash`, and `nix` workflows, and update `README.md`.

## Technical Context

**Language/Version**: Nix (Flakes, NixOS `nixos-unstable`, `nix-darwin`, Home Manager)
**Primary Dependencies**: `flake-parts`, `import-tree`, `direnv`, `nix-direnv`, `just`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `preservation`
**Storage**: Ephemeral `tmpfs` root on `homelab` with Btrfs persistence at `/persistent` via `preservation` (`~/.local/share/direnv` persisted)
**Testing**: `nix flake check` (`just check`), `deadnix` & `statix check` (`just lint`), `alejandra` (`just fmt`), and host evaluations (`homelab`, `desktop-pc`, `macbook-air-m4-15`, `iso`)
**Target Platform**: `x86_64-linux` (NixOS: `homelab`, `desktop-pc`, `iso`) and `aarch64-darwin` (`macbook-air-m4-15`)
**Project Type**: Declarative OS & service configuration repository (Dendritic Pattern)
**Performance Goals**: Instant availability of `just` and `nh` in all interactive and `opencode-web` sessions on `homelab`; cached sub-second `.envrc` (`use flake`) evaluation via `nix-direnv`
**Constraints**: Must keep `homelab` headless (`enableHomeManager = false`), avoid duplicate `direnv` hooks on `desktop-pc` and `macbook-air-m4-15`, and pass all sandbox pre-commit checks
**Scale/Scope**: 4 Nix modules (`modules/core/base.nix`, `modules/desktop/apps.nix`, `modules/core/preservation.nix`, `modules/services/opencode.nix`) + `README.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: PASS — All packages, shell hooks (`programs.direnv`), service paths (`opencode-web`), and persistent directories (`preservation`) are declared purely via Nix modules.
- **II. Dendritic Modularity & Feature-Centric Composition**: PASS — Shared foundational developer tooling moves to `modules/core/base.nix`, persistence stays in `modules/core/preservation.nix`, and `homelab.nix` remains free of inline service definitions.
- **III. Shift-Left Quality, Formatting & Static Analysis**: PASS — All changes will be validated with `alejandra`, `deadnix`, `statix`, and `nix flake check`.
- **IV. Zero-Secrets Leakage & Security First**: PASS — No secrets or credentials are introduced.
- **V. Rigorous Verification & Safe Deployment Workflow**: PASS — Directly enables `just check`, `just test`, and `just switch` on `homelab` itself.
- **VI. Living Documentation & Dual-Shell Parity**: PASS — `README.md` will be updated to reflect the shared Nix development stack in `core.base`, `direnv` persistence on `homelab`, and local self-deployment instructions with Bash/Fish parity.
- **VII. Dedicated Branch & Pull Request Workflow**: PASS — Work will be isolated on a dedicated branch (`029-homelab-dev-stack`) and submitted via a Pull Request.

## Project Structure

### Documentation (this feature)

```text
specs/029-homelab-dev-stack/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── homelab-dev-stack-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix          # Enable programs.direnv (nix-direnv) + Nix CLI dev stack on nixos & darwin
│   ├── devshell.nix      # Existing flake devShell loaded automatically by direnv (.envrc)
│   └── preservation.nix  # Persist ~/.local/share/direnv across reboots on homelab
├── desktop/
│   └── apps.nix          # Remove duplicate Nix CLI packages and programs.direnv moved to core.base
└── services/
    └── opencode.nix      # Add /run/wrappers, /run/current-system/sw, and dev tools to opencode-web path
README.md                 # Document shared Nix dev stack, direnv persistence, and homelab self-deployment
```

**Structure Decision**: Reuse existing Dendritic Pattern modules under `modules/core/`, `modules/desktop/`, and `modules/services/` without introducing unnecessary new module files.

## Complexity Tracking

> No Constitution Check violations.
