---

description: "Task list for Markdownlint Availability & Pull Request Auto-Fix"
---

# Tasks: Markdownlint Availability & Pull Request Auto-Fix

**Input**: Design documents from `/specs/034-markdownlint-pr-autofix/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Verification is performed via `quickstart.md` scenarios, `just lint-md`, `just fix-md`, `nix flake check`, and GitHub Actions workflow syntax validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Exact file paths are included in descriptions

## Path Conventions

- Root configuration: `.markdownlint-cli2.yaml`
- Workflow automation: `.github/workflows/markdownlint-fix.yml`
- Core system definitions: `modules/core/base.nix`, `modules/core/devshell.nix`
- Operational recipes: `justfile`
- Repository documentation: `README.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify repository branch state and inspect existing configuration files

- [X] T001 Verify active Git branch is `034-markdownlint-pr-autofix` and working tree is ready

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the centralized declarative Markdownlint configuration that governs file matching and directory exemption for all workflows

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Create declarative configuration in `.markdownlint-cli2.yaml` with `globs: ["**/*.md"]`, `ignores: [".agents/**"]` (`isExempt: true if path begins with .agents/`), and `config: { default: true }` per `contracts/markdownlint-config-contract.md`

**Checkpoint**: Centralized linting and exemption configuration ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Automatic Markdown Formatting in Pull Requests (Priority: P1) 🎯 MVP

**Goal**: Implement the automated GitHub Actions workflow to run `markdownlint-cli2 --fix` on Pull Requests modifying Markdown files (`path ending with .md or .markdown`) and automatically commit fixes back to the PR branch.

**Independent Test**: Push commits with intentional Markdown formatting issues in non-exempt files, trigger the workflow, and verify that fixes are automatically committed with `authorName: github-actions[bot]` and `authorEmail: github-actions[bot]@users.noreply.github.com` without human intervention.

### Implementation for User Story 1

- [X] T003 [US1] Create workflow skeleton in `.github/workflows/markdownlint-fix.yml` with triggers on `pull_request` (types: `[opened, synchronize, reopened]`) targeting `main` on paths `'**.md'` and `'**.markdown'`, and concurrency group `markdownlint-fix-${{ github.head_ref || github.ref_name }}` with `cancel-in-progress: true` per `contracts/github-workflow-contract.md`
- [X] T004 [US1] Configure workflow security permissions `permissions: contents: write` and checkout step using `actions/checkout@v4` with `ref: ${{ github.head_ref }}` in `.github/workflows/markdownlint-fix.yml`
- [X] T005 [US1] Add hermetic Nix package manager installation (`DeterminateSystems/nix-installer-action@v16`) and binary cache step (`DeterminateSystems/magic-nix-cache-action@v9`) in `.github/workflows/markdownlint-fix.yml`
- [X] T006 [US1] Add auto-fix execution step `nix shell nixpkgs#markdownlint-cli2 -c markdownlint-cli2 --fix` and auto-commit step using `stefanzweifel/git-auto-commit-action@v5` with `commit_message: "style(markdown): auto-format markdown files with markdownlint-cli2"` in `.github/workflows/markdownlint-fix.yml`

**Checkpoint**: User Story 1 is complete when `.github/workflows/markdownlint-fix.yml` is defined according to contract and ready to format PRs automatically.

---

## Phase 4: User Story 2 - Strict Exemption of Agent Instruction Directory (Priority: P2)

**Goal**: Guarantee and prove that Markdown files within `.agents/**` are strictly immune to modification by automated linting, local recipes, and CI runs.

**Independent Test**: Run `markdownlint-cli2 --fix` against a test repository state containing intentional style defects in both root documents and `.agents/**`, and verify that `.agents/**` files remain unmodified (`isExempt: true`) while non-exempt files are corrected.

### Implementation for User Story 2

- [X] T007 [US2] Verify that `.markdownlint-cli2.yaml` pattern `ignores: [".agents/**"]` is respected during recursive repository scans with zero file reads inside `.agents/`
- [X] T008 [US2] Execute validation script or command testing `markdownlint-cli2 --fix` against files in `.agents/` to assert that zero modifications or formatting changes are introduced in `.agents/**` per `quickstart.md` Scenario 2

**Checkpoint**: User Story 2 is verified when `.agents/**` files are proven to remain byte-for-byte identical after running `markdownlint-cli2 --fix`.

---

## Phase 5: User Story 3 - System-Wide Markdown Tooling Across All Configurations (Priority: P3)

**Goal**: Make `markdownlint-cli2` pre-installed and available across all host configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`), `devshell`, and expose task runner recipes in `justfile` with living documentation in `README.md`.

**Independent Test**: Run `markdownlint-cli2 --version` in NixOS and Darwin host module evaluations and `nix develop -c markdownlint-cli2 --version` per `quickstart.md` Scenario 1.

### Implementation for User Story 3

- [X] T009 [P] [US3] Add `markdownlint-cli2` to NixOS system packages in `modules/core/base.nix` (`flake.modules.core.base.nixos.environment.systemPackages`) to cover `desktop-pc`, `homelab`, and `iso`
- [X] T010 [P] [US3] Add `markdownlint-cli2` to Darwin system packages in `modules/core/base.nix` (`flake.modules.core.base.darwin.environment.systemPackages`) to cover `macbook-air-m4-15`
- [X] T011 [P] [US3] Add `markdownlint-cli2` to developer shell packages in `modules/core/devshell.nix` (`devShells.default.buildInputs`)
- [X] T012 [US3] Add `lint-md` (`markdownlint-cli2`) and `fix-md` (`markdownlint-cli2 --fix`) recipes and integrate them into composite `lint` and `fix` recipes in `justfile` per `contracts/justfile-recipes-contract.md`
- [X] T013 [US3] Update `README.md` to document `markdownlint-cli2`, the PR auto-formatting automation, and operational commands with dual **Bash** and **Fish** code blocks per Principle VI

**Checkpoint**: User Story 3 is complete when all hosts and devshell include `markdownlint-cli2`, `justfile` has Markdown recipes, and `README.md` satisfies dual-shell parity.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute end-to-end validation scenarios from `quickstart.md` and verify all repository quality gates

- [X] T014 Execute quickstart validation scenarios (`specs/034-markdownlint-pr-autofix/quickstart.md`) across CLI, `.agents/` exclusion, and `--fix` operations
- [X] T015 Run `just fmt`, `just lint`, and `just check` (`nix flake check`) across the repository to verify 100% quality gate compliance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - starts immediately.
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) - creates `.markdownlint-cli2.yaml` defining baseline rules and `.agents/**` ignores.
- **User Story 1 (Phase 3)**: Depends on Phase 2 - implements the GitHub Actions PR auto-fix workflow.
- **User Story 2 (Phase 4)**: Depends on Phase 2 - verifies strict `.agents/**` exemption behavior.
- **User Story 3 (Phase 5)**: Depends on Phase 2 - integrates packages into `modules/core/base.nix`, `modules/core/devshell.nix`, `justfile`, and `README.md`. Tasks T009, T010, and T011 can execute in parallel.
- **Polish (Phase 6)**: Depends on all user story phases (Phases 3, 4, and 5) completing.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational Phase 2 completes. No dependency on other user stories.
- **User Story 2 (P2)**: Can start after Foundational Phase 2 completes. Validates the exclusion invariant used by US1 and US3.
- **User Story 3 (P3)**: Can start after Foundational Phase 2 completes. Enhances host modules and operational recipes.

### Parallel Opportunities

- Within Phase 5 (US3):

  ```bash
  # Parallel package additions across independent files:
  Task T009: Add markdownlint-cli2 to NixOS packages in modules/core/base.nix
  Task T010: Add markdownlint-cli2 to Darwin packages in modules/core/base.nix
  Task T011: Add markdownlint-cli2 to devshell buildInputs in modules/core/devshell.nix
  ```

- User Stories 1, 2, and 3 touch distinct files (`.github/workflows/markdownlint-fix.yml`, `.markdownlint-cli2.yaml`, `modules/core/base.nix` / `justfile` / `README.md`) and can proceed concurrently once Phase 2 is complete.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002) - establish `.markdownlint-cli2.yaml`
3. Complete Phase 3: User Story 1 (T003 - T006) - implement `.github/workflows/markdownlint-fix.yml`
4. **STOP and VALIDATE**: Verify workflow syntax and local execution
5. Deliver initial MVP automated PR formatting

### Incremental Delivery

1. Setup + Foundational → Repository baseline configuration ready (`.markdownlint-cli2.yaml`)
2. Add User Story 1 → PR auto-fix workflow active (MVP!)
3. Add User Story 2 → Empirical test validation of `.agents/**` exemption
4. Add User Story 3 → `markdownlint-cli2` pre-installed across all host profiles, `devshell`, `justfile` recipes, and `README.md`
5. Polish → Flake checks and full pre-commit gate validation (`just check`)
