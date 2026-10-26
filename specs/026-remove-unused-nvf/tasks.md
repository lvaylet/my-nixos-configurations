---

description: "Task list for Remove Unused nvf Dependency"
---

# Tasks: Remove Unused nvf Dependency

**Input**: Design documents from `/specs/026-remove-unused-nvf/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Verification is performed via the repository's standard quality gate suite (`just fmt`, `just lint`, `just check`) per `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Pre-implementation verification of active repository state

- [X] T001 Audit `modules/` and `flake.nix` to confirm zero active `.nix` modules reference `inputs.nvf` or `programs.nvf`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core prerequisites before modifying the flake dependency graph

- [X] T002 Inspect `flake.lock` root inputs and node graph to confirm `nvf`, `mnw`, and `flake-compat_2` are the only `nvf`-exclusive nodes in `flake.lock`

**Checkpoint**: Foundation verified - User Story 1 implementation can now proceed

---

## Phase 3: User Story 1 - Clean Up Obsolete Neovim Configuration Dependency (Priority: P1) 🎯 MVP

**Goal**: Remove the unused `nvf` flake input from `flake.nix` and prune `nvf` and its exclusive transitive lock nodes (`mnw`, `flake-compat_2`) from `flake.lock` without altering other locked revisions.

**Independent Test**: Verify `nvf`, `mnw`, and `flake-compat_2` are absent from `flake.nix` and `flake.lock`, and confirm `just check` passes with exit code 0.

### Implementation for User Story 1

- [X] T003 [US1] Remove the unused `nvf` input block and its comment from `flake.nix`
- [X] T004 [US1] Synchronize `flake.lock` using `nix flake lock` to prune `nvf`, `mnw`, and `flake-compat_2` in `flake.lock`
- [X] T005 [US1] Verify `git diff flake.lock` shows only the removal of `nvf`, `mnw`, and `flake-compat_2` with zero revision changes to remaining inputs in `flake.lock`

**Checkpoint**: User Story 1 is complete and independently verifiable

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Quality gate validation across all repository configurations

- [X] T006 Run `just fmt` and `just lint` to validate formatting (`alejandra`) and static analysis (`deadnix`, `statix`) across `flake.nix` and `modules/`
- [X] T007 Run `just check` (`nix flake check`) to validate flake outputs and pre-commit checks across all targets (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`) per `specs/026-remove-unused-nvf/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - verifies lockfile graph before mutation
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
  - `T003` (`flake.nix`) → `T004` (`flake.lock`) → `T005` (`flake.lock` diff verification)
- **Polish (Phase 4)**: Depends on User Story 1 completion (`T006` → `T007`)

### User Story Dependencies

- **User Story 1 (P1)**: Single user story for this feature; no cross-story dependencies.

### Parallel Opportunities

- `T001` (auditing `modules/`) and `T002` (inspecting `flake.lock`) touch distinct files and can be executed in parallel during pre-checks.
- `T003` and `T004` must run sequentially because `nix flake lock` reads `flake.nix` to update `flake.lock`.

---

## Parallel Example: Pre-Implementation Verification

```bash
# Audit modules/ and inspect flake.lock concurrently:
Task: "Audit modules/ and flake.nix to confirm zero active .nix modules reference inputs.nvf or programs.nvf"
Task: "Inspect flake.lock root inputs and node graph to confirm nvf, mnw, and flake-compat_2 are the only nvf-exclusive nodes in flake.lock"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`)
2. Complete Phase 2: Foundational (`T002`)
3. Complete Phase 3: User Story 1 (`T003`–`T005`)
4. Complete Phase 4: Polish & Quality Gates (`T006`–`T007`)
5. **STOP and VALIDATE**: Confirm `just fmt`, `just lint`, and `just check` pass with exit code 0.
