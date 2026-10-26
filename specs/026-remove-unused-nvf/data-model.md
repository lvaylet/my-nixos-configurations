# Data Model: Remove Unused nvf Dependency

**Feature**: `026-remove-unused-nvf`
**Date**: 2026-10-26

## Entities

### 1. Flake Input Manifest (`flake.nix`)

Represents the top-level declarative dependency graph for the repository.

- **Removed Attribute**:
  - `inputs.nvf`:
    - `url`: `"github:NotAShelf/nvf"`
    - `inputs.nixpkgs.follows`: `"nixpkgs"`
- **Retained Attributes**:
  - `nixpkgs`, `home-manager`, `darwin`, `noctalia`, `disko`, `preservation`, `git-hooks`, `opencode`, `flake-parts`, `import-tree`.

### 2. Flake Lock Graph (`flake.lock`)

Represents the pinned dependency resolution graph (lockfile schema version 7).

- **Removed Root Reference**:
  - `nodes.root.inputs.nvf` (`"nvf"`)
- **Pruned Lock Nodes**:
  - `nodes.nvf` (`github:NotAShelf/nvf`, rev `19992540d372466340ededda0c065a3a0a962fd6`)
  - `nodes.mnw` (`github:Gerg-L/mnw`, rev `0151d9fa87992cbeb67c86616fb9170dcec830b6` — exclusively referenced by `nvf`)
  - `nodes.flake-compat_2` (`https://git.lix.systems/lix-project/flake-compat.git`, rev `382052b74656a369c5408822af3f2501e9b1af81` — exclusively referenced by `nvf`)
- **Invariants**:
  - All remaining nodes in `nodes` retain their exact `locked.rev` and `locked.narHash`.
  - Every node in `nodes` is reachable from `nodes.root`.
