---
description: "Task list for migrating SSH settings from deprecated matchBlocks"
---

# Tasks: Migrate SSH Settings from Deprecated MatchBlocks

**Input**: Design documents from `/specs/009-migrate-ssh-settings/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline inspection of current evaluation diagnostics and generated configuration

- [X] T001 Inspect current evaluation warning on `desktop-pc` and baseline `.ssh/config` output in `modules/services/ssh.nix`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify option schema and prerequisite contracts before user story changes

**⚠️ CRITICAL**: Blocking prerequisite for all subsequent user stories

- [X] T002 Verify Home Manager `programs.ssh.settings` schema compatibility and directive naming in `modules/services/ssh.nix`

**Checkpoint**: Foundation ready - option schema confirmed and ready for module refactoring

---

## Phase 3: User Story 1 - Clean and Warning-Free Build Diagnostics (Priority: P1) 🎯 MVP

**Goal**: Replace deprecated `programs.ssh.matchBlocks` with `programs.ssh.settings` in `modules/services/ssh.nix` to eliminate build evaluation warnings

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` and `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath` and verify zero deprecation warnings emitted

### Implementation for User Story 1

- [X] T003 [US1] Replace `programs.ssh.matchBlocks` with `programs.ssh.settings` while keeping `enableDefaultConfig = false` in `modules/services/ssh.nix`
- [X] T004 [US1] Validate elimination of build evaluation warnings across `desktop-pc` and `homelab` configurations in `modules/services/ssh.nix`

**Checkpoint**: User Story 1 is functional: build and evaluation logs are completely free of deprecation warnings

---

## Phase 4: User Story 2 - Transparent Remote Host Connectivity Parity (Priority: P1)

**Goal**: Ensure generated OpenSSH client configuration preserves exact directives for all declared remote hosts (`rpi3` and `homelab-vm`)

**Independent Test**: Query `nix eval --raw .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file.".ssh/config".text` and verify both host blocks match expected directives

### Implementation for User Story 2

- [X] T005 [US2] Verify `rpi3` OpenSSH host configuration directives (`HostName`, `User`, `IdentityFile`, `CheckHostIP no`) render correctly in `modules/services/ssh.nix`
- [X] T006 [US2] Verify `homelab-vm` OpenSSH host configuration directives (`HostName`, `User`, `IdentityFile`, `CheckHostIP no`) render correctly in `modules/services/ssh.nix`

**Checkpoint**: User Story 2 is functional: client SSH configuration provides 100% directive parity with the pre-migration baseline

---

## Phase 5: User Story 3 - Repository Code Hygiene and Standards Compliance (Priority: P2)

**Goal**: Pass all automated code formatting, static linting, and dead code detection quality gates

**Independent Test**: Run `just fmt` and `just lint` with exit code 0 and zero warnings

### Implementation for User Story 3

- [X] T007 [P] [US3] Format `modules/services/ssh.nix` with `alejandra` via `just fmt`
- [X] T008 [P] [US3] Run static analysis with `statix check` and dead code detection with `deadnix` on `modules/services/ssh.nix` via `just lint`

**Checkpoint**: User Story 3 is functional: module strictly satisfies repository style and linting standards

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end quality validation across all targets and sandboxes

- [X] T009 Execute hermetic pre-commit checks across all targets with `just check`
- [X] T010 Validate complete quickstart verification scenarios in `specs/009-migrate-ssh-settings/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
  - **User Story 1 (P1)**: Implements core schema replacement in `modules/services/ssh.nix` (MVP)
  - **User Story 2 (P1)**: Validates rendered host directives (depends on US1 implementation)
  - **User Story 3 (P2)**: Validates formatting and static analysis (can run after US1/US2)
- **Polish (Phase 6)**: Depends on all user stories being complete

### Parallel Opportunities

- Within Phase 5, formatting (T007) and linting (T008) can execute in parallel.
- Host configuration verifications (T005 and T006) test independent host blocks.

---

## Parallel Example: User Story 3

```bash
# Run formatting and linting checks in parallel:
Task: "Format modules/services/ssh.nix with alejandra via just fmt"
Task: "Run static analysis with statix check and dead code detection with deadnix on modules/services/ssh.nix via just lint"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002)
3. Complete Phase 3: User Story 1 (T003, T004)
4. **STOP and VALIDATE**: Confirm that `programs.ssh.matchBlocks` warning is completely eliminated from evaluation output

### Incremental Delivery

1. Setup + Foundational → Baseline captured and schema verified
2. User Story 1 → Migrate option schema to `programs.ssh.settings`, eliminating warnings (MVP)
3. User Story 2 → Verify generated `~/.ssh/config` content for `rpi3` and `homelab-vm`
4. User Story 3 → Format and lint with project quality tooling
5. Polish → Hermetic pre-commit checks and quickstart verification pass cleanly
