---

description: "Task list for Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity"
---

# Tasks: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Input**: Design documents from `/specs/027-refactor-core-modules/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Verified via `nix eval`, `just fmt`, `just lint`, and `just check`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify branch isolation and baseline repository state

- [X] T001 Verify active Git branch `027-refactor-core-modules` and feature tracking in `.specify/feature.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create the modular bootloader feature definitions before modifying `modules/core/base.nix` and host configurations

- [X] T002 Create `modules/core/bootloader.nix` defining `flake.modules.core.limine` and `flake.modules.core.grub`

**Checkpoint**: Modular bootloader features exist and are auto-discovered by `import-tree ./modules`

---

## Phase 3: User Story 1 - Decouple Bootloaders into Modular Features (Priority: P1) 🎯 MVP

**Goal**: Remove `boot.loader` from `modules/core/base.nix` and enable `core.limine` on `desktop-pc` and `core.grub` on `homelab` without `lib.mkForce` overrides.

**Independent Test**: Run `nix eval` on `desktop-pc` and `homelab` bootloader options to confirm `desktop-pc` enables Limine, `homelab` enables GRUB 2 without `lib.mkForce`, and `modules/core/base.nix` has zero `boot.loader` settings.

### Implementation for User Story 1

- [X] T003 [US1] Remove `boot.loader` block from `modules/core/base.nix`
- [X] T004 [P] [US1] Add `core.limine` to `features` in `modules/hosts/desktop-pc.nix`
- [X] T005 [P] [US1] Add `core.grub` to `features` and remove inline `boot.loader` overrides from `modules/hosts/homelab.nix`

**Checkpoint**: User Story 1 is complete and independently verifiable via `nix eval`

---

## Phase 4: User Story 2 - Deduplicate Shell Shortcuts and Use Native Fish Abbreviations (Priority: P2)

**Goal**: Factor `systemdAliases` and `gitAliases` into shared `let` bindings in `modules/core/base.nix`, set `programs.fish.shellAbbrs` across `nixos` and `darwin`, and remove manual `complete -c` wrapper commands.

**Independent Test**: Evaluate `programs.fish.shellAbbrs`, `environment.shellAliases`, and `programs.fish.interactiveShellInit` across `desktop-pc`, `homelab`, and `macbook-air-m4-15`.

### Implementation for User Story 2

- [X] T006 [US2] Refactor `modules/core/base.nix` to define shared `systemdAliases` and `gitAliases` in `let`, configure `programs.fish.shellAbbrs` on `nixos` and `darwin`, and remove manual `complete -c` commands from `programs.fish.interactiveShellInit`

**Checkpoint**: User Stories 1 and 2 are complete and independently verifiable

---

## Phase 5: User Story 3 - Reference Centralized User Identity in SSH Client Configuration (Priority: P3)

**Goal**: Replace hardcoded `"laurent"` username in `modules/services/ssh.nix` with `vars.userName`.

**Independent Test**: Evaluate `home-manager.users.laurent.programs.ssh.settings.homelab.User` on `desktop-pc` and `macbook-air-m4-15`.

### Implementation for User Story 3

- [X] T007 [P] [US3] Update `modules/services/ssh.nix` `homeManager` module to accept `{vars, ...}:` and set `User = vars.userName;`

**Checkpoint**: All 3 user stories are complete and independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation synchronization (`README.md`) and full constitutional quality gates

- [X] T008 Update `README.md` to document native Fish abbreviations (`programs.fish.shellAbbrs`) and modular bootloader features (`core.limine`, `core.grub`)
- [X] T009 Stage new files in Git (`git add`), run `just fmt`, `just lint`, `just check`, and verify all quickstart `nix eval` assertions pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup - creates `modules/core/bootloader.nix`
- **User Story 1 (Phase 3)**: Depends on Phase 2 (`modules/core/bootloader.nix`)
- **User Story 2 (Phase 4)**: Modifies `modules/core/base.nix` (sequential after T003)
- **User Story 3 (Phase 5)**: Independent file (`modules/services/ssh.nix`), can run in parallel with US1/US2
- **Polish (Phase 6)**: Depends on Phases 3, 4, and 5

### Parallel Opportunities

- `T004` (`modules/hosts/desktop-pc.nix`), `T005` (`modules/hosts/homelab.nix`), and `T007` (`modules/services/ssh.nix`) touch distinct files and can be executed in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & Phase 2 (`modules/core/bootloader.nix`)
2. Complete Phase 3 (Decouple bootloaders in `base.nix`, `desktop-pc.nix`, `homelab.nix`)
3. Validate bootloader evaluation on `desktop-pc` and `homelab`

### Incremental Delivery

1. Deliver US1 (Bootloader decoupling)
2. Deliver US2 (Shared shell shortcuts & native `programs.fish.shellAbbrs`)
3. Deliver US3 (`vars.userName` in `modules/services/ssh.nix`)
4. Update `README.md` and run full quality gate verification (`just fmt`, `just lint`, `just check`)
