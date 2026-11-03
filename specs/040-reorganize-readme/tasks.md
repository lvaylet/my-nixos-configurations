---
description: "Task list for reorganizing README.md for progressive disclosure and modularity"
---

# Tasks: Reorganize README for Progressive Disclosure and Clarity

**Input**: Design documents from `/specs/040-reorganize-readme/`

**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Validation scenarios in `specs/040-reorganize-readme/quickstart.md` serve as acceptance checks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths

---

## Phase 1: Setup (Directory Structure)

**Purpose**: Create destination directory tree for modular documentation.

- [X] T001 Verify git branch is `040-reorganize-readme` and working tree is ready
- [X] T002 Create modular documentation directories `docs/hosts`, `docs/services`, and `docs/reference`

---

## Phase 2: Foundational (Modular Extraction Prerequisites)

**Purpose**: Extract detailed runbooks and exhaustive reference tables into `docs/` before trimming `README.md`, guaranteeing zero loss of technical instructions or broken references.

**⚠️ CRITICAL**: Must complete before restructuring `README.md`.

- [X] T003 [P] Create `docs/hosts/macbook.md` with macOS M4 provisioning, `/etc/synthetic.conf`, `nix-darwin` switch, daily ops, rollback, and client access per `specs/040-reorganize-readme/contracts/host-runbooks-contract.md`
- [X] T004 [P] Create `docs/hosts/homelab.md` with headless `nixos-anywhere` bootstrap, custom ISO build, impermanent storage architecture, and updates per `specs/040-reorganize-readme/contracts/host-runbooks-contract.md`
- [X] T005 [P] Create `docs/services/homelab-services.md` with all 10 service recipes, reverse proxy architecture, Cloudflare DNS-01, WAHA pairing, Home Assistant proxy, and storage permissions per `specs/040-reorganize-readme/contracts/service-runbook-contract.md`
- [X] T006 [P] Create `docs/reference/shell-aliases.md` with systemctl, journalctl, Git (25+ aliases), Fish extensions, Nord theme specs, Noctalia wallpapers, FiraCode typography, and editor setups per `specs/040-reorganize-readme/contracts/reference-contract.md`

**Checkpoint**: Foundation ready - all deep runbooks and cheat sheets safely extracted into `docs/`.

---

## Phase 3: User Story 1 - Welcoming Landing Page for Visitors (Priority: P1) 🎯 MVP

**Goal**: Transform `README.md` into an inviting overview hub (< 200 lines) with high-level orientation, host topology, architecture overview, quickstart, and documentation index.

**Independent Test**: Read `README.md` from top to bottom; verify that a newcomer can understand repository purpose, host topology matrix, architecture overview, and basic development shell access without scrolling past lengthy installation manuals.

### Implementation for User Story 1

- [X] T007 [US1] Restructure top sections of `README.md` with project title, CI badge, elevator pitch, Managed Hosts Topology matrix, and Dendritic Pattern summary per `specs/040-reorganize-readme/contracts/readme-contract.md`
- [X] T008 [US1] Streamline Quickstart & Environment Setup section in `README.md` covering Devbox (`devbox shell`) and native Nix Flakes (`direnv allow` / `nix develop`)
- [X] T009 [US1] Add compact Hosted Services Summary table and Reverse Proxy Endpoints table in `README.md` linking directly to `docs/services/homelab-services.md`
- [X] T010 [US1] Add Documentation Directory index section in `README.md` with links to `docs/hosts/macbook.md`, `docs/hosts/homelab.md`, `docs/services/homelab-services.md`, and `docs/reference/shell-aliases.md`

**Checkpoint**: At this point, User Story 1 is fully functional and delivers an inviting, scannable MVP landing page.

---

## Phase 4: User Story 2 - Efficient Operational Navigation for Maintainers (Priority: P2)

**Goal**: Provide fast, structured access to everyday workflows (`just` recipes, remote deployment commands, quality gates) with strict dual-shell (Bash & Fish) command parity.

**Independent Test**: Verify that all core operational workflows (`just` recipes, remote SSH deployment patterns, dual Bash/Fish command variants, quality gate checks) are grouped logically in a dedicated, scannable section with explicit navigation.

### Implementation for User Story 2

- [X] T011 [US2] Restructure Operational Recipes (`justfile`) section in `README.md` into a scannable table grouped by lifecycle verbs (`build`, `test`, `switch`, `boot`, `check`, `fmt`, `lint`)
- [X] T012 [US2] Update Remote Deployments over SSH and Quality Gates sections in `README.md` with concise dual Bash and Fish command blocks
- [X] T013 [US2] Audit all shell commands across `README.md` and `docs/` to guarantee strict dual-shell (Bash and Fish) parity per Constitution Principle VI

**Checkpoint**: At this point, User Stories 1 AND 2 are complete, providing both an inviting landing page and fast operational reference.

---

## Phase 5: User Story 3 - Streamlined Reference and Modular Runbooks under `docs/` (Priority: P3)

**Goal**: Validate and polish modular runbooks and reference tables under `docs/`, ensuring zero broken links, complete secret safety, and clean table formatting.

**Independent Test**: Verify that all detailed configuration instructions for homelab services and full alias tables remain 100% intact, accurate, and navigable.

### Implementation for User Story 3

- [X] T014 [US3] Verify bidirectional link integrity: check all links from `README.md` to `docs/` and breadcrumb links `[← Back to README](../../README.md)` in `docs/hosts/macbook.md`, `docs/hosts/homelab.md`, `docs/services/homelab-services.md`, and `docs/reference/shell-aliases.md`
- [X] T015 [US3] Verify secret generation commands in `docs/services/homelab-services.md` (`/dev/urandom` snippets) contain zero plaintext credentials or private keys per Constitution Principle IV
- [X] T016 [US3] Format and verify pipe alignment for all tables in `docs/reference/shell-aliases.md` (Git aliases, systemctl, journalctl, Fish extensions, Nord theme)

**Checkpoint**: All three user stories are complete, verified, and cross-linked.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate line budget, markdownlint compliance, and repository checks.

- [X] T017 Verify `README.md` line count is strictly under 200 lines (`wc -l < README.md`) per Success Criterion SC-001
- [X] T018 Run `just lint-md` and `just fix-md` to ensure zero markdownlint issues across all documentation files
- [X] T019 Run full validation scenarios from `specs/040-reorganize-readme/quickstart.md`
- [X] T020 Run `just check` (`nix flake check`) to verify flake evaluation integrity and pre-commit checks

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS User Story 1 (ensures all content is safely extracted to `docs/` before `README.md` is trimmed)
- **User Story 1 (Phase 3 - P1)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4 - P2)**: Depends on User Story 1 completion
- **User Story 3 (Phase 5 - P3)**: Can proceed concurrently with US2 or sequentially
- **Polish (Phase 6)**: Depends on all user story phases being complete

### Parallel Opportunities

- Tasks T003, T004, T005, and T006 in Phase 2 touch completely separate files under `docs/` and can run in parallel:
  - T003: `docs/hosts/macbook.md`
  - T004: `docs/hosts/homelab.md`
  - T005: `docs/services/homelab-services.md`
  - T006: `docs/reference/shell-aliases.md`
- Tasks T014, T015, and T016 in Phase 5 inspect distinct aspects across files and can run in parallel.

---

## Parallel Example: Foundational Phase

```bash
# Launch extraction of all modular documentation in parallel:
Task: "Create docs/hosts/macbook.md per specs/040-reorganize-readme/contracts/host-runbooks-contract.md"
Task: "Create docs/hosts/homelab.md per specs/040-reorganize-readme/contracts/host-runbooks-contract.md"
Task: "Create docs/services/homelab-services.md per specs/040-reorganize-readme/contracts/service-runbook-contract.md"
Task: "Create docs/reference/shell-aliases.md per specs/040-reorganize-readme/contracts/reference-contract.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational extraction (T003–T006)
3. Complete Phase 3: User Story 1 (T007–T010)
4. **STOP and VALIDATE**: Verify `README.md` line count (< 200 lines) and readability
5. Landing page MVP is achieved without any loss of extracted content

### Incremental Delivery

1. Phase 1 + 2: Destination files created and all technical runbooks safely extracted into `docs/`
2. Phase 3 (US1): Streamlined `README.md` landing hub operational (MVP!)
3. Phase 4 (US2): Operational recipes organized with strict dual-shell (Bash & Fish) parity
4. Phase 5 (US3): Cross-document link verification, secret safety, and alias table polishing
5. Phase 6 (Polish): Markdownlint validation (`just lint-md`) and flake checks (`just check`)
