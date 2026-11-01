---

description: "Task list for automated container image updates via Podman and systemd timer"
---

# Tasks: Automated Container Image Updates via Podman and Systemd Timer

**Input**: Design documents from `/specs/037-podman-auto-update/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/container-auto-update-contract.md, quickstart.md

**Tests**: Standalone test suites are not requested; verification is performed via hermetic Nix evaluation (`nix eval`), static analysis (`just lint`), formatting checks (`just fmt`), and flake sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dedicated branch isolation per Constitution Principle VII.

- [X] T001 Create and switch to dedicated feature branch `037-podman-auto-update` from `main` in repository root `.git`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — `virtualisation.podman` and `virtualisation.oci-containers` are already configured on `homelab` in `modules/services/podman.nix`.)*

---

## Phase 3: User Story 1 - Daily Automated Inspection and Container Refresh (Priority: P1) 🎯 MVP

**Goal**: Configure the daily systemd timer and service in `modules/services/podman.nix` (`systemd.timers.podman-auto-update` and `systemd.services.podman-auto-update`) with daily schedule, persistent catch-up, randomized delay, and post-update image pruning.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.timerConfig` and `nixosConfigurations.homelab.config.systemd.services.podman-auto-update.serviceConfig` via `nix eval` per `specs/037-podman-auto-update/quickstart.md` to confirm the timer runs daily with persistence and the service executes `podman auto-update`.

### Implementation for User Story 1

- [X] T002 [US1] Declare `systemd.timers.podman-auto-update` and `systemd.services.podman-auto-update` in `modules/services/podman.nix`
- [X] T003 [US1] Verify `homelab` systemd timer and service configuration via `nix eval` against `modules/services/podman.nix`

**Checkpoint**: User Story 1 complete — `homelab` evaluates with an active daily `podman-auto-update` systemd timer and oneshot service.

---

## Phase 4: User Story 2 - Comprehensive Lifecycle Management for Portainer and Managed Services (Priority: P1)

**Goal**: Add `--label=io.containers.autoupdate=registry` across all declared OCI containers in `modules/services/` so that Portainer CE and all homelab service containers are tracked and automatically updated.

**Independent Test**: Evaluate `virtualisation.oci-containers.containers.<name>.extraOptions` across `portainer`, `homeassistant`, `filebrowser`, `waha`, `n8n`, and `n8n-runners` via `nix eval` to confirm all containers contain the auto-update label.

### Implementation for User Story 2

- [X] T004 [P] [US2] Add `"--label=io.containers.autoupdate=registry"` to `extraOptions` in `modules/services/portainer.nix`
- [X] T005 [P] [US2] Add `"--label=io.containers.autoupdate=registry"` to `extraOptions` in `modules/services/home-automation.nix`
- [X] T006 [P] [US2] Add `"--label=io.containers.autoupdate=registry"` to `extraOptions` in `modules/services/filebrowser.nix`
- [X] T007 [P] [US2] Add `"--label=io.containers.autoupdate=registry"` to `extraOptions` in `modules/services/waha.nix`
- [X] T008 [P] [US2] Add `"--label=io.containers.autoupdate=registry"` to `extraOptions` for `n8n` and `n8n-runners` in `modules/services/n8n.nix`
- [X] T009 [US2] Verify all container labels via `nix eval` across `modules/services/` per `specs/037-podman-auto-update/quickstart.md`

**Checkpoint**: User Story 2 complete — all homelab OCI containers (including Portainer) are labeled for registry digest tracking and auto-updates.

---

## Phase 5: User Story 3 - On-Demand Manual Update Execution (Priority: P2)

**Goal**: Add a dedicated recipe `update-containers target="homelab"` under `[group('container-management')]` in `justfile` to enable immediate manual checks and container updates both locally and over SSH.

**Independent Test**: Run `just --list` to confirm recipe registration under `[container-management]`, and execute `just --dry-run update-containers` to verify local and remote branch logic.

### Implementation for User Story 3

- [X] T010 [US3] Add `update-containers` recipe under `[group('container-management')]` in `justfile`
- [X] T011 [US3] Verify `just --list` displays `update-containers` and validate recipe syntax in `justfile`

**Checkpoint**: User Story 3 complete — operators can trigger `podman auto-update` on demand across local and remote targets.

---

## Phase 6: User Story 4 - Operational Documentation and Dual-Shell Command Parity (Priority: P3)

**Goal**: Update `README.md` to document the daily automated update mechanism, systemd timer monitoring, and manual update triggers with dual Bash and Fish command examples per Constitution Principle VI.

**Independent Test**: Inspect `README.md` to confirm the presence of container auto-update documentation, service monitoring commands (`systemctl list-timers`), and dual Bash/Fish operational commands.

### Implementation for User Story 4

- [X] T012 [US4] Document container auto-update timer, manual recipe, and monitoring with dual Bash/Fish syntax in `README.md`

**Checkpoint**: User Story 4 complete — documentation is fully synchronized with dual-shell command parity.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Execute all repository quality gates, formatters, static linters, and full flake checks.

- [X] T013 [P] Format all modified Nix and markdown files (`just fmt`) across repository root
- [X] T014 [P] Run static analysis and linting (`just lint`) across repository root
- [X] T015 Run full hermetic sandbox check (`just check`) and validate all evaluation commands in `specs/037-podman-auto-update/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Must complete first (`T001`) so all work is isolated on branch `037-podman-auto-update`.
- **User Story 1 (Phase 3)**: Starts after `T001` (`T002` → `T003`).
- **User Story 2 (Phase 4)**: Starts after `T001` (`T004`-`T008` in parallel → `T009`); modifies individual container service files independently.
- **User Story 3 (Phase 5)**: Starts after `T001` (`T010` → `T011`); modifies `justfile`.
- **User Story 4 (Phase 6)**: Starts after completion of US1, US2, and US3 (`T012`); documents the full feature in `README.md`.
- **Polish (Phase 7)**: Depends on completion of all user stories (`T013`-`T014` in parallel → `T015`).

### User Story Dependencies

- **User Story 1 (P1)**: Independent MVP — establishes the core systemd timer and service in `modules/services/podman.nix`.
- **User Story 2 (P1)**: Independent container label enablement across service modules.
- **User Story 3 (P2)**: Independent CLI operational recipe in `justfile`.
- **User Story 4 (P3)**: Documentation synchronization in `README.md` referencing US1, US2, and US3.

### Parallel Opportunities

- Tasks `T004`, `T005`, `T006`, `T007`, and `T008` touch completely separate service files (`portainer.nix`, `home-automation.nix`, `filebrowser.nix`, `waha.nix`, `n8n.nix`) and can execute in parallel.
- User Story 1 (`podman.nix`), User Story 2 (individual container modules), and User Story 3 (`justfile`) touch disjoint files and can proceed in parallel once Phase 1 is complete.
- Polish tasks `T013` (`just fmt`) and `T014` (`just lint`) can execute in parallel before final `T015` (`just check`).

---

## Parallel Example: User Story 2 (Container Labels)

```bash
# Launch container label modifications in parallel across separate service files:
Task T004: "Add io.containers.autoupdate=registry to extraOptions in modules/services/portainer.nix"
Task T005: "Add io.containers.autoupdate=registry to extraOptions in modules/services/home-automation.nix"
Task T006: "Add io.containers.autoupdate=registry to extraOptions in modules/services/filebrowser.nix"
Task T007: "Add io.containers.autoupdate=registry to extraOptions in modules/services/waha.nix"
Task T008: "Add io.containers.autoupdate=registry to extraOptions in modules/services/n8n.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 & Portainer Container Label)

1. Complete Phase 1: Setup (`T001`)
2. Complete Phase 3: User Story 1 (`T002`, `T003`)
3. Complete User Story 2 task for Portainer (`T004`)
4. **STOP and VALIDATE**: Verify timer and Portainer label evaluation via `nix eval`

### Incremental Delivery

1. Setup branch `037-podman-auto-update` (`T001`)
2. Implement systemd timer and service (`T002`, `T003`) → US1 MVP ready
3. Apply labels across all services in parallel (`T004`-`T008`) and verify (`T009`) → US2 ready
4. Add `update-containers` recipe in `justfile` (`T010`, `T011`) → US3 ready
5. Synchronize documentation in `README.md` (`T012`) → US4 ready
6. Run repo-wide quality gates (`T013`-`T015`) → Production-ready Pull Request
