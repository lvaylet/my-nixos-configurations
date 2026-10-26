# Implementation Plan: Harmonize Task Runner (`justfile`) Recipes and Syntax Across Hosts

**Branch**: `028-harmonize-justfile-recipes` | **Date**: 2026-10-26 | **Spec**: [`specs/028-harmonize-justfile-recipes/spec.md`](./spec.md)

**Input**: Feature specification from `/specs/028-harmonize-justfile-recipes/spec.md`

## Summary

Harmonize all machine build, test, deployment, and installation recipes in `justfile` by replacing disparate host-suffixed and conflicting recipes (`deploy-homelab`, `test-homelab`, `install-homelab`, `build-darwin`, `test-darwin`, `switch-darwin`) with a single unified set of parameterized lifecycle verbs (`build`, `test`, `switch`, `boot`, `install`, plus `build-iso`). Implement automatic local host detection when `configuration` is omitted (`macbook-air-m4-15` on macOS, or current NixOS hostname `desktop-pc` / `homelab` on Linux), automatic remote target resolution when targeting another NixOS host (e.g., `just switch homelab`), and unified privilege elevation via `sudo` / `--use-remote-sudo` (and `nh os --elevation-strategy passwordless`) across all machines. Synchronize `README.md` with the updated `just --list` output and dual Bash/Fish command examples.

## Technical Context

**Language/Version**: `just` task runner syntax + POSIX/Bash recipe scripts (`#!/usr/bin/env bash` with `set -euo pipefail`), Nix Flakes (`26.05`)

**Primary Dependencies**: `just`, `nh` (`>= 4.4.2`, with fallback to `nixos-rebuild` / `nix`), `nix-darwin`, `nixos-anywhere`

**Storage**: N/A (stateless task runner recipes and Markdown documentation)

**Testing**: `just --list`, `just --dry-run`, `just fmt`, `just lint`, `just check` (`nix flake check`)

**Target Platform**: Multi-platform (`x86_64-linux` NixOS & non-NixOS Linux, `aarch64-darwin` macOS)

**Project Type**: Declarative NixOS / `nix-darwin` multi-host configuration repository

**Performance Goals**: Instant local/remote CLI dispatch (`< 50ms` recipe overhead prior to Nix evaluation)

**Constraints**: Must work seamlessly across `desktop-pc` (where `PermitRootLogin = "no"` and `wheelNeedsPassword = false`), `homelab` (where `laurent` has `wheelNeedsPassword = false`), and `macbook-air-m4-15` (where `nix-darwin` activation requires `sudo`). Must maintain dual Bash/Fish command parity in `README.md`.

**Scale/Scope**: 2 primary files (`justfile`, `README.md`) across 4 flake host targets (`desktop-pc`, `homelab`, `macbook-air-m4-15`, `iso`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: **PASS** — No imperative state changes introduced; all recipes invoke declarative flake targets (`.#nixosConfigurations.*` and `.#darwinConfigurations.*`).
- **II. Dendritic Modularity & Feature-Centric Composition**: **PASS** — No changes to `modules/` hierarchy required; host compositions remain pure.
- **III. Shift-Left Quality, Formatting & Static Analysis**: **PASS** — All changes will be validated via `just fmt`, `just lint`, and `just check` (`nix flake check`).
- **IV. Zero-Secrets Leakage & Security First**: **PASS** — No credentials or secrets involved; uses existing declarative SSH identities and `sudo` elevation.
- **V. Rigorous Verification & Safe Deployment Workflow**: **PASS** — Strengthens Principle V by making `justfile` a truly uniform single source of truth across all hosts (`build`, `test`, `switch`, `boot`, `install`).
- **VI. Living Documentation & Dual-Shell Parity**: **PASS** — `README.md` will be updated in the same branch with synchronized `just --list` output and dual **Bash** and **Fish** command blocks.
- **VII. Dedicated Branch & Pull Request Workflow**: **PASS** — Work is isolated on dedicated branch `028-harmonize-justfile-recipes`.

*Post-Phase 1 Design Re-Check*: **PASS** — All 7 constitutional principles remain satisfied with zero violations.

## Project Structure

### Documentation (this feature)

```text
specs/028-harmonize-justfile-recipes/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── justfile-cli.md  # Phase 1 CLI contract for justfile recipes
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
justfile                 # Unified task runner recipes ((re)build, dev-utils, flake-management, garbage-collection)
README.md                # Living documentation synchronized with unified justfile syntax and Bash/Fish examples
```

**Structure Decision**: Existing root-level `justfile` and `README.md` are updated in-place in accordance with the repository's layout.

## Complexity Tracking

No constitutional violations require justification.
