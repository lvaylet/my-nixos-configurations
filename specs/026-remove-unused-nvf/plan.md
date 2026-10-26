# Implementation Plan: Remove Unused nvf Dependency

**Branch**: `026-remove-unused-nvf` | **Date**: 2026-10-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/026-remove-unused-nvf/spec.md`

## Summary

Remove the obsolete `nvf` (`github:NotAShelf/nvf`) input declaration from `flake.nix` and synchronize `flake.lock` via `nix flake lock` to prune the `nvf` node along with its exclusive transitive dependencies (`mnw` and `flake-compat_2`), without altering the locked revisions of any remaining active inputs.

## Technical Context

**Language/Version**: Nix (Flakes, NixOS `nixos-unstable`, `nix-darwin`)

**Primary Dependencies**: `nixpkgs`, `flake-parts`, `import-tree`, `home-manager`, `darwin`, `noctalia`, `disko`, `preservation`, `git-hooks`, `opencode` (removing `nvf`)

**Storage**: N/A (declarative configuration manifest and lockfile)

**Testing**: `just fmt` (`alejandra`), `just lint` (`deadnix`, `statix`), `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc`, `homelab`, `iso`), `aarch64-darwin` (`macbook-air-m4-15`)

**Project Type**: Declarative multi-host NixOS and nix-darwin flake repository (Dendritic Pattern)

**Performance Goals**: Eliminate 3 unused flake lock nodes (`nvf`, `mnw`, `flake-compat_2`) to speed up `nix flake update` and reduce evaluation metadata overhead

**Constraints**: Must not alter pinned revisions of any remaining active inputs in `flake.lock`; must pass all pre-commit and flake checks with exit code 0

**Scale/Scope**: 2 modified root files (`flake.nix`, `flake.lock`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
|-----------|--------|---------------|
| **I. Declarative & Hermetic Configuration** | PASS | Cleans up `flake.nix` and `flake.lock` deterministically via `nix flake lock`, preserving pinned revisions of all active inputs. |
| **II. Dendritic Modularity & Feature-Centric Composition** | PASS | No module hierarchy changes needed; Neovim is already modularized in `modules/core/neovim.nix` using LazyVim. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | PASS | Removes dead flake input (`nvf`) and validates with `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | PASS | No secrets or credentials involved; reduces third-party dependency surface area. |
| **V. Rigorous Verification & Safe Deployment Workflow** | PASS | Verified with `just fmt`, `just lint`, and `just check` (`nix flake check`). |
| **VI. Living Documentation & Dual-Shell Parity** | PASS | `README.md` already accurately documents `modules/core/neovim.nix` (LazyVim) with zero `nvf` references; `quickstart.md` provides both Bash and Fish command blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | PASS | All work is isolated on branch `026-remove-unused-nvf` and will be submitted via a dedicated Pull Request targeting `main`. |

## Project Structure

### Documentation (this feature)

```text
specs/026-remove-unused-nvf/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── checklists/
│   └── requirements.md  # Spec quality checklist (/speckit.specify command)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
flake.nix                # Root flake manifest (remove unused `nvf` input)
flake.lock               # Root flake lockfile (prune `nvf`, `mnw`, `flake-compat_2`)
modules/
├── core/
│   ├── neovim.nix       # Active shared Neovim/LazyVim module (unchanged)
│   └── dotfiles/nvim/   # Active LazyVim Lua starter config (unchanged)
├── desktop/
├── services/
└── hosts/
```

**Structure Decision**: Existing Dendritic Pattern structure at repository root; only `flake.nix` and `flake.lock` require modification.

## Complexity Tracking

No constitution violations to justify.
