---

description: "Task list for fast CI workflow (removing machine builds)"
---

# Tasks: Fast CI Workflow (Remove Machine Builds)

**Input**: Design documents from `/specs/038-fast-ci-workflow/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/ci-workflow-contract.md, quickstart.md

**Tests**: Standalone automated test suites are not requested; verification is performed via workflow syntax validation, hermetic flake checks (`nix flake check`), static analysis (`just lint`), Markdown linting (`just lint-md`), and repository sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dedicated branch isolation per Constitution Principle VII.

- [X] T001 Create and switch to dedicated feature branch `038-fast-ci-workflow` from `main` in repository root `.git`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — existing GitHub Actions workflow infrastructure and flake check definitions are active in `.github/workflows/ci.yml` and `flake.nix`.)*

---

## Phase 3: User Story 1 - Fast Continuous Integration Feedback on Pull Requests (Priority: P1) 🎯 MVP

**Goal**: Remove the `build` matrix job from `.github/workflows/ci.yml` while preserving the `check` job running `nix flake check --print-build-logs`, caching, triggers, and concurrency control.

**Independent Test**: Verify via `grep` that `.github/workflows/ci.yml` contains only the `check` job under `jobs:` and no `build:` matrix job, and confirm the workflow file adheres to `specs/038-fast-ci-workflow/contracts/ci-workflow-contract.md`.

### Implementation for User Story 1

- [X] T002 [US1] Remove `build` matrix job and retain single `check` job in `.github/workflows/ci.yml` per `specs/038-fast-ci-workflow/contracts/ci-workflow-contract.md`
- [X] T003 [US1] Validate workflow file syntax and job structure in `.github/workflows/ci.yml` per `specs/038-fast-ci-workflow/quickstart.md` Scenario 1

**Checkpoint**: User Story 1 complete — `.github/workflows/ci.yml` defines exclusively the fast `check` job and contains zero machine build jobs.

---

## Phase 4: User Story 2 - Preserved Flake Evaluation and Security Validation (Priority: P2)

**Goal**: Ensure `nix flake check` validates the entire repository hermetically, verifying flake syntax, NixOS configuration evaluation for all machines, formatters, and pre-commit security and linting hooks.

**Independent Test**: Run `nix flake check --print-build-logs` locally and verify that all derivation checks (including `pre-commit-check`, `devShells`, `packages`, and `nixosConfigurations`) evaluate and succeed with exit code `0`.

### Implementation for User Story 2

- [X] T004 [US2] Run local flake check (`nix flake check --print-build-logs`) to verify evaluation of all host configurations and pre-commit checks per `specs/038-fast-ci-workflow/quickstart.md` Scenario 2

**Checkpoint**: User Story 2 complete — `nix flake check` verified locally with 100% pass rate.

---

## Phase 5: User Story 3 - Synchronized Living Documentation of the CI Architecture (Priority: P3)

**Goal**: Update `README.md` under `## Continuous Integration` to accurately reflect the single-stage `nix flake check` pipeline, removing deprecated references to the multi-machine build matrix and explaining local compilation before deployment.

**Independent Test**: Inspect `README.md` under `## Continuous Integration` and verify it describes the single-stage quality gate without referencing matrix system builds.

### Implementation for User Story 3

- [X] T005 [US3] Update `## Continuous Integration` section in `README.md` to document the single-stage `nix flake check` pipeline and local machine compilation workflow

**Checkpoint**: User Story 3 complete — `README.md` accurately describes the streamlined CI pipeline.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Repository formatting, linting, and hermetic sandbox checks across all modified files.

- [X] T006 [P] Format all modified YAML, Markdown, and repository files (`just fmt`) across repository root
- [X] T007 [P] Run Markdown linting and validation (`just lint-md`) across repository root
- [X] T008 [P] Run static analysis and linting (`just lint`) across repository root
- [X] T009 Run full hermetic sandbox check (`just check`) across repository root

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — branch isolation active.
- **Foundational (Phase 2)**: No prerequisites blocking work.
- **User Story 1 (Phase 3)**: Modifies `.github/workflows/ci.yml`.
- **User Story 2 (Phase 4)**: Validates `nix flake check` execution against repository state.
- **User Story 3 (Phase 5)**: Updates `README.md` documentation. Can run in parallel with US1/US2 as it touches a distinct file.
- **Polish (Phase 6)**: Runs after all user story modifications to ensure clean quality gates.

### User Story Dependencies

- **User Story 1 (P1)**: Independent — updates `.github/workflows/ci.yml`.
- **User Story 2 (P2)**: Independent — validates flake checks locally.
- **User Story 3 (P3)**: Independent — updates `README.md`.

---

## Parallel Execution Examples

### User Stories 1 and 3 in Parallel

Since User Story 1 touches `.github/workflows/ci.yml` and User Story 3 touches `README.md`, they can proceed concurrently:

```bash
# Developer / Agent A: User Story 1
Task: "T002 [US1] Remove build matrix job and retain single check job in .github/workflows/ci.yml"

# Developer / Agent B: User Story 3
Task: "T005 [US3] Update ## Continuous Integration section in README.md"
```

### Quality Gate Polish in Parallel

```bash
# Launch formatting and linting tasks in parallel:
Task: "T006 [P] Format all modified YAML, Markdown, and repository files (just fmt)"
Task: "T007 [P] Run Markdown linting and validation (just lint-md)"
Task: "T008 [P] Run static analysis and linting (just lint)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (branch `038-fast-ci-workflow`).
2. Complete Phase 3: User Story 1 (remove build matrix from `.github/workflows/ci.yml`).
3. Validate: Verify with Scenario 1 of `quickstart.md` (`grep` for `jobs:` structure).
4. Delivers immediate MVP value: CI runs in under 3 minutes without compiling machine closures.

### Incremental Delivery

1. Setup verified (Phase 1)
2. User Story 1 delivered → CI workflow streamlined (.github/workflows/ci.yml)
3. User Story 2 verified → Hermetic flake checks confirmed locally (nix flake check)
4. User Story 3 delivered → Living documentation synchronized (README.md)
5. Phase 6 Polish completed → All repository linters and sandbox checks pass
