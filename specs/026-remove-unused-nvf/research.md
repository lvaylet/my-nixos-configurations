# Research: Remove Unused nvf Dependency

**Feature**: `026-remove-unused-nvf`
**Date**: 2026-10-26

## Decision 1: Pruning `nvf` and Transitive Dependencies Without Upgrading Other Inputs

- **Decision**: Remove the `nvf` block from `inputs` in `flake.nix` and execute `nix flake lock` (rather than `nix flake update` or `just up`).
- **Rationale**: `nix flake lock` reconciles `flake.lock` with the current `inputs` attribute set in `flake.nix` without fetching newer revisions for existing locked inputs. It deterministically removes `"nvf": "nvf"` from `nodes.root.inputs`, deletes the `nvf` lock node, and garbage-collects any transitive lock nodes referenced solely by `nvf` (`mnw` and `flake-compat_2`), while preserving `nixpkgs`, `home-manager`, `darwin`, `noctalia`, `disko`, `preservation`, `git-hooks`, `opencode`, `flake-parts`, and `import-tree` at their exact current hashes.
- **Alternatives considered**:
  - `nix flake update` / `just up`: Rejected because it updates all flake inputs to their latest upstream commits, introducing unrelated changes outside the scope of Issue #34.
  - Manual JSON editing of `flake.lock`: Rejected because `nix flake lock` natively enforces the lockfile schema (version 7) and graph reachability invariants without human error.

## Decision 2: Verifying Zero Active References to `nvf` Across Modules

- **Decision**: Audit all `.nix` files under `modules/` and `flake.nix` prior to and after removal, and run `just check` (`nix flake check`) to confirm all NixOS (`desktop-pc`, `homelab`, `iso`) and nix-darwin (`macbook-air-m4-15`) configurations evaluate cleanly.
- **Rationale**: In spec 008 (`008-declarative-lazyvim`) and spec 017 (`017-share-neovim-config`), `nvf` was replaced by the shared declarative LazyVim setup in `modules/core/neovim.nix` and `modules/core/dotfiles/nvim/`. A full repository search confirms zero `.nix` modules under `modules/` reference `inputs.nvf` or `programs.nvf`.
- **Alternatives considered**:
  - Keeping `nvf` commented out in `flake.nix`: Rejected by Principle III (Shift-Left Quality, Formatting & Static Analysis / dead-code elimination) and Issue #34.

## Decision 3: Documentation (`README.md`) & Historical Specs Handling

- **Decision**: Keep `README.md` and historical `specs/001-*` through `specs/015-*` unchanged.
- **Rationale**: `README.md` was already updated in earlier features to document `Neovim/LazyVim` (`modules/core/neovim.nix`) and contains zero references to `nvf`. Historical specs under `specs/` document past architectural milestones and should remain untouched as archival records.
- **Alternatives considered**:
  - Editing historical spec files: Rejected because historical specs record the state of the system at the time those features were designed.
