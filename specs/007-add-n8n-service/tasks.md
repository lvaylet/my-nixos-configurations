---
description: "Task list for n8n workflow automation service implementation"
---

# Tasks: n8n Workflow Automation Service for Homelab

**Input**: Design documents from `/specs/007-add-n8n-service/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing container runtime and preservation prerequisites

- [X] T001 Verify Podman OCI container backend and container storage preservation in `modules/services/podman.nix`

---

## Phase 2: Foundational (Module Discovery & Service Skeleton)

**Purpose**: Establish the dendritic module skeleton for auto-discovery before user stories begin

**⚠️ CRITICAL**: Blocking prerequisite for all n8n service configuration

- [X] T002 Create dendritic service module skeleton `modules/services/n8n.nix` exporting `flake.modules.services.n8n.nixos`

**Checkpoint**: Foundation ready - n8n service module skeleton is discovered by `import-tree`

---

## Phase 3: User Story 1 - Visual Workflow Design and Automation (Priority: P1) 🎯 MVP

**Goal**: Configure the n8n OCI container runtime with web UI access, non-root user execution, and localized timezone settings

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.image` (returns `"docker.io/n8nio/n8n:latest"`) and verify port bindings and environment variables

### Implementation for User Story 1

- [X] T003 [US1] Configure OCI container definition in `modules/services/n8n.nix` with image `"docker.io/n8nio/n8n:latest"`, non-root user `"1000:1000"`, port mapping `["5678:5678"]`, and environment variables `TZ = "Europe/Paris"`, `GENERIC_TIMEZONE = "Europe/Paris"`, `N8N_PORT = "5678"`, `N8N_DEFAULT_BINARY_DATA_MODE = "filesystem"`, and `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true"`

**Checkpoint**: User Story 1 container parameters are fully declared

---

## Phase 4: User Story 2 - State and Credential Persistence Across Restarts (Priority: P1)

**Goal**: Configure volume mounts and declarative state preservation under `/persistent` so workflows and credentials survive reboots

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` and confirm `/var/lib/n8n` is preserved with `user = "1000"`, `group = "1000"`, and `mode = "0750"`

### Implementation for User Story 2

- [X] T004 [US2] Configure persistent storage volume `"/var/lib/n8n:/home/node/.n8n"` and systemd mount ordering `systemd.services."podman-n8n".after = [ "local-fs.target" ]` in `modules/services/n8n.nix`
- [X] T005 [US2] Declare colocated state preservation for `directory = "/var/lib/n8n"` with `user = "1000"`, `group = "1000"`, and `mode = "0750"` under `preservation.preserveAt."/persistent".directories` in `modules/services/n8n.nix`

**Checkpoint**: User Story 2 is functional: storage volumes and preservation rules ensure zero state loss on reboot

---

## Phase 5: User Story 4 - Modular Host Integration and Lifecycle Management (Priority: P1)

**Goal**: Compose `services.n8n` into the `homelab` host definition in `modules/hosts/homelab.nix` following the Dendritic Pattern

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n` and confirm the container is active on `homelab` with zero inline service definitions

### Implementation for User Story 4

- [X] T006 [US4] Add `services.n8n` to the `features` list in `modules/hosts/homelab.nix` via `config.flake.modules.services.n8n` without inline service definitions

**Checkpoint**: User Story 4 is functional: n8n is assembled into `homelab` and evaluated cleanly by the NixOS configuration

---

## Phase 6: User Story 3 - Event-Driven Webhook Integration (Priority: P2)

**Goal**: Allow incoming network traffic for webhooks and the web UI through the host firewall

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts` and verify port `5678` is included

### Implementation for User Story 3

- [X] T007 [US3] Open inbound TCP port 5678 in the host firewall via `networking.firewall.allowedTCPPorts = [ 5678 ]` in `modules/services/n8n.nix`

**Checkpoint**: User Story 3 is functional: webhook endpoints and web UI are reachable over the local network

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, flake evaluation, and regression validation across all targets

- [X] T008 [P] Format all Nix expressions using `just fmt` (`alejandra`)
- [X] T009 [P] Run static analysis and dead code checks via `just lint` (`statix check`, `deadnix`)
- [X] T010 Verify system derivation graph evaluation for `homelab`, `desktop-pc`, and `iso` targets per `specs/007-add-n8n-service/quickstart.md`
- [X] T011 Run hermetic pre-commit checks in sandbox via `just check` (`nix flake check`)
- [X] T012 Validate all end-to-end scenarios documented in `specs/007-add-n8n-service/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
  - **User Story 1 (P1)**: Depends on Phase 2 - Configures container settings (MVP)
  - **User Story 2 (P1)**: Depends on US1 - Configures storage mounts and preservation
  - **User Story 4 (P1)**: Depends on US1 and US2 - Composes feature into `homelab.nix`
  - **User Story 3 (P2)**: Depends on US1 - Configures firewall port for webhooks
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete

### Parallel Opportunities

- Within Phase 7 (Polish): `T008` [P] and `T009` [P] can run in parallel.
- Regression evaluations for `homelab`, `desktop-pc`, and `iso` in `T010` can run concurrently.

---

## Implementation Strategy

### MVP First (User Stories 1, 2 & 4)

1. Complete Phase 1: Setup (`modules/services/podman.nix` verification)
2. Complete Phase 2: Foundational (`modules/services/n8n.nix` skeleton)
3. Complete Phase 3: User Story 1 (Container settings in `modules/services/n8n.nix`)
4. Complete Phase 4: User Story 2 (Volumes and preservation in `modules/services/n8n.nix`)
5. Complete Phase 5: User Story 4 (Enable in `modules/hosts/homelab.nix`)
6. **STOP and VALIDATE**: Verify `homelab` evaluates with n8n container, volumes, and preservation
7. Complete Phase 6: User Story 3 (Firewall port in `modules/services/n8n.nix`)
8. Complete Phase 7: Polish (Format, lint, evaluation, pre-commit checks)
