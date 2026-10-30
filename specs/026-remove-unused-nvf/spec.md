# Feature Specification: Remove Unused nvf Dependency

**Feature Branch**: `026-remove-unused-nvf`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Travaille sur <https://github.com/lvaylet/my-nixos-configurations/issues/34> pour nettoyer les dépendances. Avance de manière autonome sur les étapes "speckit.plan", "speckit.tasks" puis "speckit.implement" si aucune intervention de ma part n'est nécessaire, par exemple pour clarifier ou analyser tes propositions. Après la phase d'implémentation, crée une Pull Request dédiée. Je la validerai manuellement."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean Up Obsolete Neovim Configuration Dependency (Priority: P1)

As a system maintainer, I want to remove the unused `nvf` upstream dependency and its transitive lockfile entries from the repository so that dependency updates are faster, the dependency graph reflects only actively used inputs, and no obsolete configuration frameworks remain tracked.

**Why this priority**: `nvf` was completely superseded by the shared declarative LazyVim configuration (introduced in spec 008 and unified in spec 017). Keeping `nvf` in the dependency declarations and lockfile causes unnecessary upstream fetches during dependency updates and misleads maintainers about which Neovim management solution is active.

**Independent Test**: Can be fully tested by inspecting the project's dependency manifest and lockfile to confirm `nvf` and its exclusive transitive dependencies (`mnw`, `flake-compat_2`) are absent, then running the repository's automated evaluation and quality checks to verify all host configurations still evaluate cleanly.

**Acceptance Scenarios**:

1. **Given** the repository dependency manifest (`flake.nix`), **When** a maintainer inspects the declared inputs, **Then** `nvf` is no longer listed as an input.
2. **Given** the repository dependency lockfile (`flake.lock`), **When** the lockfile is synchronized after removing `nvf`, **Then** the `nvf` node and its unreferenced transitive inputs (`mnw` and `flake-compat_2`) are removed while all remaining active inputs stay locked at their existing revisions.
3. **Given** all managed system targets (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`), **When** the repository verification suite runs, **Then** all configurations evaluate and pass quality checks without errors or regressions to the active LazyVim Neovim setup.

---

### Edge Cases

- What happens if another active input shares a transitive dependency with `nvf` (such as `nixpkgs`)? Only `nvf` and nodes exclusively referenced by `nvf` (`mnw`, `flake-compat_2`) are pruned; shared nodes remain intact at their current pinned revisions.
- What happens if unintentional version bumps occur during lockfile cleanup? Lockfile synchronization must only prune unreferenced inputs without upgrading or altering the locked revisions of remaining active inputs.
- Are any active modules still referencing `inputs.nvf`? A repository-wide check confirms zero active modules under `modules/` reference `nvf`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository dependency declaration MUST remove the unused `nvf` input and its associated comment.
- **FR-002**: The repository dependency lockfile MUST be updated to prune the `nvf` root input reference and all orphaned lock nodes (`nvf`, `mnw`, `flake-compat_2`) without changing the locked revisions of other active inputs.
- **FR-003**: All active system configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`) MUST continue to evaluate cleanly and retain their existing Neovim/LazyVim functionality.
- **FR-004**: Repository formatting, static analysis, dead-code checks, and hermetic validation checks MUST pass with zero errors or warnings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero references to `nvf` remain in active configuration manifests (`flake.nix`, `flake.lock`, and `modules/`).
- **SC-002**: 100% of orphaned lock nodes exclusive to `nvf` (`nvf`, `mnw`, `flake-compat_2`) are eliminated from `flake.lock`, reducing locked dependency nodes by 3.
- **SC-003**: 100% of repository quality gates (formatting, static linting, and flake evaluation checks) succeed with exit code 0.
- **SC-004**: Zero unintended revision changes occur on any remaining active dependencies in `flake.lock`.

## Assumptions

- Historical specification documents under `specs/001-*`, `specs/002-*`, `specs/004-*`, `specs/005-*`, `specs/008-*`, and `specs/015-*` are archival records of past feature iterations and are intentionally left unmodified.
- `README.md` already accurately documents `Neovim/LazyVim` (`modules/core/neovim.nix`) and contains no outdated references to `nvf` in active service or architecture sections.
- No other flake input in `flake.nix` should have its revision updated as part of this cleanup; only the removal of `nvf` and its orphaned lockfile entries is in scope per Issue #34.
