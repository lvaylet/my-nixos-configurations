---

description: "Task list for Harmonize Task Runner (justfile) Recipes and Syntax Across Hosts"
---

# Tasks: Harmonize Task Runner (`justfile`) Recipes and Syntax Across Hosts

**Input**: Design documents from `/specs/028-harmonize-justfile-recipes/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/justfile-cli.md`, `quickstart.md`

**Tests**: Verification is performed via `just --list`, `just --dry-run`, `just fmt`, `just lint`, and `just check` as defined in `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Exact file paths are included in descriptions

## Path Conventions

- Root task runner file: `justfile`
- Project documentation: `README.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify branch isolation and inspect existing `justfile` and `README.md` baseline

- [X] T001 Verify active Git branch is `028-harmonize-justfile-recipes` and inspect current recipes in `justfile`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared host and OS auto-detection logic in `justfile` that all `(re)build` lifecycle recipes rely on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Define consistent default `configuration` resolution rules (`macbook-air-m4-15` when `uname -s == "Darwin"`, local `hostname -s` when matching `homelab` or `desktop-pc` on Linux, else `desktop-pc`) across lifecycle recipes in `justfile`

**Checkpoint**: Host resolution design ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Unified Lifecycle Verbs Across All Machines (Priority: P1) 🎯 MVP

**Goal**: Replace heterogeneous host-suffixed recipes (`build-darwin`, `test-darwin`, `switch-darwin`, `deploy-homelab`, `test-homelab`, `install-homelab`) with the 5 unified parameterized lifecycle verbs (`build`, `test`, `switch`, `boot`, `install`) plus `build-iso` in `justfile`.

**Independent Test**: Run `just --list` and verify that only `boot`, `build`, `build-iso`, `install`, `switch`, and `test` appear under `[(re)build]`, and verify local/Darwin dispatch via `just --dry-run`.

### Implementation for User Story 1

- [X] T003 [US1] Update `build configuration="" target=""` in `justfile` to auto-detect `CONFIG` (`macbook-air-m4-15` on Darwin, local hostname or `desktop-pc` on Linux) and build `.#darwinConfigurations.${CONFIG}.system` for Darwin or `.#nixosConfigurations.${CONFIG}` (via `nh os build` / `nix build` / `nixos-rebuild build`) for NixOS
- [X] T004 [US1] Update `test configuration="" target=""` in `justfile` to support both Darwin (`nix build --no-link --print-out-paths .#darwinConfigurations.${CONFIG}.system` followed by `sudo "${systemConfig}/activate"` when `uname -s == "Darwin"`) and NixOS (`nh os test` / `nixos-rebuild test`)
- [X] T005 [US1] Update `switch configuration="" target=""` in `justfile` to support both Darwin (`sudo nix run nix-darwin -- switch --flake .#${CONFIG}` when `uname -s == "Darwin"`) and NixOS (`nh os switch` / `nixos-rebuild switch`)
- [X] T006 [US1] Update `boot configuration="" target=""` in `justfile` to auto-detect `CONFIG`, reject Darwin (`macbook-air-m4-15`) with a clear error message, and run `nh os boot` / `nixos-rebuild boot` for NixOS
- [X] T007 [US1] Rename `install-homelab target` to `install target configuration="homelab"` in `justfile`, rejecting Darwin configurations and bootstrapping `.#${configuration}` via `nixos-anywhere`
- [X] T008 [US1] Remove obsolete host-suffixed recipes (`build-darwin`, `test-darwin`, `switch-darwin`, `deploy-homelab`, `test-homelab`) from `justfile`

**Checkpoint**: User Story 1 is complete when `just --list` shows the unified `(re)build` recipe set and all legacy host-suffixed recipes are removed.

---

## Phase 4: User Story 2 - Seamless Local & Remote Targeting with `sudo` Elevation (Priority: P2)

**Goal**: Standardize automatic remote `target` inference and `sudo` / `--use-remote-sudo` privilege elevation across `desktop-pc`, `homelab`, and `macbook-air-m4-15` in `justfile`.

**Independent Test**: Verify via `just --dry-run` and guard execution tests that targeting a remote NixOS host (`just test homelab`, `just switch homelab`, `just boot homelab`) automatically infers `TARGET="homelab"` when run from another machine and uses `--elevation-strategy passwordless` (with `nh`) or `--use-remote-sudo` (with `nixos-rebuild`), while local NixOS fallback uses `sudo nixos-rebuild` and `clean-all` uses `sudo nix-collect-garbage --delete-old`.

### Implementation for User Story 2

- [X] T009 [US2] Implement automatic remote `TARGET` resolution in `test`, `switch`, and `boot` in `justfile` so that when `target` is empty and (`! -e /etc/NIXOS` or `hostname -s != "${CONFIG}"`), `TARGET` defaults to `"${CONFIG}"`
- [X] T010 [US2] Standardize remote and local privilege elevation in `test`, `switch`, and `boot` in `justfile` (`nh os <action> .#"${CONFIG}" --elevation-strategy passwordless --target-host "${TARGET}"` when `nh` is available remotely, `nixos-rebuild <action> --flake .#"${CONFIG}" --target-host "${TARGET}" --use-remote-sudo` fallback remotely, and `sudo nixos-rebuild <action> --flake .#"${CONFIG}"` fallback locally)
- [X] T011 [US2] Ensure `clean-all` in `justfile` uses `sudo nix-collect-garbage --delete-old` when falling back on macOS or non-`nh` systems so system-wide profiles are cleaned with proper privileges

**Checkpoint**: User Stories 1 and 2 are complete and verified via `just --list` and `just --dry-run`.

---

## Phase 5: User Story 3 - Synchronized Living Documentation & Dual-Shell Parity (Priority: P3)

**Goal**: Update `README.md` so the `just --list` reference, remote deployment examples, macOS (`macbook-air-m4-15`) daily operations, Homelab (`homelab`) provisioning/deployment examples, and Quality Gates section reflect the unified `justfile` syntax with dual Bash and Fish variants.

**Independent Test**: Grep `README.md` for removed recipe names (`deploy-homelab`, `test-homelab`, `install-homelab`, `build-darwin`, `test-darwin`, `switch-darwin`) to confirm 0 matches, and verify all updated Bash/Fish command blocks.

### Implementation for User Story 3

- [X] T012 [P] [US3] Update the `Operational Recipes (justfile)` `just --list` code block and `Remote Deployments over SSH` examples in `README.md`
- [X] T013 [US3] Update the `macOS Workstation Deployment (macbook-air-m4-15)` -> `Routine Maintenance & Daily Operations` section in `README.md` to replace `build-darwin`, `test-darwin`, and `switch-darwin` with `just build`, `just test`, and `just switch` (including both Bash and Fish blocks)
- [X] T014 [US3] Update the `Initial Provisioning of Homelab` and `Homelab Hosted Services` sections in `README.md` to replace `install-homelab`, `deploy-homelab`, and `test-homelab` with `just install`, `just switch`, and `just test` (preserving dual Bash and Fish blocks)
- [X] T015 [US3] Update the `Local / Non-NixOS Building` and `Quality Gates & Verification Workflow` sections in `README.md` to use the unified `just build`, `just test`, and `just switch` syntax

**Checkpoint**: All user stories are complete and `README.md` is 100% synchronized with `justfile`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run end-to-end validation scenarios from `quickstart.md` and execute all repository quality gates

- [X] T016 Execute `quickstart.md` validation scenarios (`just --list`, `just --dry-run`, and cross-OS error guard checks) against `justfile`
- [X] T017 Run `just fmt`, `just lint`, and `just check` across the repository to verify 100% quality gate compliance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - starts immediately.
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) - establishes shared host resolution rules in `justfile`.
- **User Story 1 (Phase 3)**: Depends on Phase 2 - implements the unified lifecycle verbs in `justfile`.
- **User Story 2 (Phase 4)**: Depends on Phase 3 - refines remote target auto-inference and `sudo` / `--use-remote-sudo` privilege elevation in `justfile`.
- **User Story 3 (Phase 5)**: Can proceed in parallel with Phase 4 once CLI contract (`contracts/justfile-cli.md`) is fixed, as it modifies `README.md` (a different file from `justfile`).
- **Polish (Phase 6)**: Depends on Phases 3, 4, and 5 completion.

### User Story Dependencies

- **User Story 1 (P1)**: Core MVP — unifies the recipe names and platform dispatch in `justfile`.
- **User Story 2 (P2)**: Enhances `justfile` recipes from US1 with smart remote `target` resolution and unified `sudo` elevation across all hosts.
- **User Story 3 (P3)**: Synchronizes `README.md` with the CLI contract from US1 and US2.

### Parallel Opportunities

- Once the CLI contract in `contracts/justfile-cli.md` is established, `justfile` updates (US1/US2: `T003`–`T011`) and `README.md` updates (US3: `T012`–`T015`) operate on separate files (`justfile` vs `README.md`) and can be drafted in parallel.

---

## Parallel Example: User Story 2 & User Story 3

```bash
# Task in justfile (US2):
Task: "T009 [US2] Implement automatic remote TARGET resolution in test, switch, and boot in justfile"

# Parallel task in README.md (US3):
Task: "T012 [P] [US3] Update the Operational Recipes (justfile) just --list code block and Remote Deployments over SSH examples in README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 & Phase 2 (`T001`–`T002`).
2. Complete Phase 3: User Story 1 (`T003`–`T008`) in `justfile`.
3. **VALIDATE**: Run `just --list` and `just --dry-run` to confirm unified verbs.

### Incremental Delivery

1. Deliver Unified Lifecycle Verbs (US1) + Smart Remote Targeting & `sudo` Elevation (US2) in `justfile`.
2. Deliver Living Documentation Synchronization (US3) in `README.md`.
3. Validate with `quickstart.md` checks and `just fmt`, `just lint`, `just check` (Phase 6).
