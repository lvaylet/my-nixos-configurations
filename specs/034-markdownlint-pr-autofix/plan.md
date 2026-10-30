# Implementation Plan: Markdownlint Availability & Pull Request Auto-Fix

**Branch**: `034-markdownlint-pr-autofix` | **Date**: 2026-10-30 | **Spec**: [`specs/034-markdownlint-pr-autofix/spec.md`](./spec.md)

**Input**: Feature specification from `/specs/034-markdownlint-pr-autofix/spec.md`

## Summary

Incorporate `markdownlint-cli2` into all repository host configurations (NixOS hosts `desktop-pc`, `homelab`, `iso`, and Darwin host `macbook-air-m4-15`) and the common development shell (`devShells.default`). Define a declarative root configuration `.markdownlint-cli2.yaml` targeting `**/*.md` while strictly exempting the `.agents/` subfolder. Implement an automated Pull Request GitHub Actions workflow (`.github/workflows/markdownlint-fix.yml`) that executes `markdownlint-cli2 --fix` on modified documentation and automatically pushes formatting corrections back to the PR branch. Add operational recipes (`lint-md`, `fix-md`) to `justfile` and update `README.md` with dual Bash and Fish documentation.

## Technical Context

**Language/Version**: Nix Flakes (`26.05`), GitHub Actions Workflow YAML, YAML configuration (`.markdownlint-cli2.yaml`), `just` task runner syntax

**Primary Dependencies**: `pkgs.markdownlint-cli2` (v0.23.x / markdownlint v0.41.x), `DeterminateSystems/nix-installer-action@v16`, `DeterminateSystems/magic-nix-cache-action@v9`, `stefanzweifel/git-auto-commit-action@v5`

**Storage**: N/A (stateless linting engine and Git commit automation)

**Testing**: `nix flake check`, `just lint`, `just fix`, `just lint-md`, `just fix-md`, GitHub Actions workflow execution

**Target Platform**: Multi-platform (`x86_64-linux` NixOS, `aarch64-darwin` macOS, GitHub Actions runner `ubuntu-latest`)

**Project Type**: Declarative NixOS/Darwin multi-host infrastructure and CI automation

**Performance Goals**: < 10 seconds execution time for linting/fixing repository Markdown files; zero perceptible CLI overhead

**Constraints**: Strict exclusion of `.agents/**`; safe branch permissions (`contents: write`) for PR auto-commits; zero commit pollution on clean PRs; dual Bash/Fish operational instructions in `README.md`

**Scale/Scope**: 4 primary configuration files (`modules/core/base.nix`, `modules/core/devshell.nix`, `justfile`, `README.md`), 1 root configuration (`.markdownlint-cli2.yaml`), and 1 workflow (`.github/workflows/markdownlint-fix.yml`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: **PASS** — `markdownlint-cli2` is packaged hermetically via pinned `nixpkgs` in `flake.lock`. Tooling configuration is declared cleanly in `.markdownlint-cli2.yaml`.
- **II. Dendritic Modularity & Feature-Centric Composition**: **PASS** — Package is added to `modules/core/base.nix` and `modules/core/devshell.nix`, maintaining dendritic modularity without violating host boundary constraints.
- **III. Shift-Left Quality, Formatting & Static Analysis**: **PASS** — Directly strengthens Principle III by adding automated Markdown styling and linting to the repository's static quality gates.
- **IV. Zero-Secrets Leakage & Security First**: **PASS** — Uses standard GitHub token permissions (`contents: write`) restricted to the active PR branch. No credentials or secrets committed.
- **V. Rigorous Verification & Safe Deployment Workflow**: **PASS** — All changes are verified via `nix flake check` and `just check`. Operational recipes exposed in `justfile`.
- **VI. Living Documentation & Dual-Shell Parity**: **PASS** — `README.md` will be updated with usage instructions and dual **Bash** and **Fish** code blocks for all Markdown commands.
- **VII. Dedicated Branch & Pull Request Workflow**: **PASS** — Work is executed on isolated dedicated branch `034-markdownlint-pr-autofix`.

*Post-Phase 1 Design Re-Check*: **PASS** — All architectural choices (declarative root configuration, dedicated PR auto-fix action, base module package integration) fully comply with all 7 constitutional principles.

## Project Structure

### Documentation (this feature)

```text
specs/034-markdownlint-pr-autofix/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── github-workflow-contract.md
│   ├── markdownlint-config-contract.md
│   └── justfile-recipes-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
.markdownlint-cli2.yaml                 # Centralized declarative glob patterns and .agents/** exclusion
.github/workflows/markdownlint-fix.yml  # Pull Request auto-fix workflow running markdownlint-cli2 --fix
modules/core/base.nix                   # Package addition for NixOS and Darwin configurations
modules/core/devshell.nix               # Package addition for repository development shell
justfile                                # Recipes lint-md, fix-md, and integration into lint / fix
README.md                               # Living documentation with dual Bash/Fish command parity
```

**Structure Decision**: Uses existing repository conventions for core packages, task runner recipes, and GitHub workflows, with `.markdownlint-cli2.yaml` colocated at the repository root for immediate discovery by tools and editors.

## Complexity Tracking

No constitutional violations require justification.
