---
description: "Task list for enabling Python 3 script execution on homelab and in n8n Code nodes"
---

# Tasks: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Input**: Design documents from `/specs/016-add-n8n-python3/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/n8n-python-runner-contract.md`, `quickstart.md`

**Tests**: Verification and evaluation tasks follow the repository's NixOS evaluation and quality gate workflow defined in `quickstart.md` and `.specify/memory/constitution.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing Podman networking, container DNS resolution, and `homelab` feature composition prerequisites

- [X] T001 [P] Verify Podman OCI container backend and container-to-container DNS resolution (`defaultNetwork.settings.dns_enabled = true`) in `modules/services/podman.nix`
- [X] T002 [P] Verify `services.n8n` feature composition in `modules/hosts/homelab.nix` and inspect current container definition in `modules/services/n8n.nix`

---

## Phase 2: Foundational (Module Signature & Shared Authentication Token Bootstrap)

**Purpose**: Update the `modules/services/n8n.nix` module signature to accept `pkgs` and configure automatic, idempotent runtime generation of `/var/lib/n8n/runners.env` before any task runner containers start

**⚠️ CRITICAL**: Blocking prerequisite before configuring external task runners in `modules/services/n8n.nix`

- [X] T003 Add `pkgs` to the `flake.modules.services.n8n.nixos` module arguments (`{ config, lib, pkgs, vars, ... }:`) and configure `systemd.services."podman-n8n".preStart` in `modules/services/n8n.nix` to idempotently create `/var/lib/n8n/runners.env` (`0:0`, `0600`) with a 256-bit random `N8N_RUNNERS_AUTH_TOKEN`, enforcing the Zero-Secrets Invariant ("`N8N_RUNNERS_AUTH_TOKEN` MUST NEVER appear in Nix source files or Git history; it is generated at runtime into `/var/lib/n8n/runners.env` if missing")

**Checkpoint**: Foundation ready — `modules/services/n8n.nix` has access to `pkgs` and self-bootstraps `/var/lib/n8n/runners.env` safely on service startup

---

## Phase 3: User Story 1 - Execute Python 3 Scripts in n8n Code Nodes (Priority: P1) 🎯 MVP

**Goal**: Configure `n8n` in external task runner mode and deploy the `n8n-runners` sidecar container with a declarative `/etc/n8n-task-runners.json` configuration enabling native Python 3 and standard library imports in n8n `Code` nodes

**Independent Test**: Evaluate `.#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers` (`n8n` and `n8n-runners`) to confirm `N8N_RUNNERS_MODE = "external"`, `N8N_NATIVE_PYTHON_RUNNER = "true"`, `N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679"`, and `"N8N_RUNNERS_STDLIB_ALLOW": "*"` in the mounted `n8n-task-runners.json`

### Implementation for User Story 1

- [X] T004 [US1] Define the `taskRunnersConfig` derivation (`pkgs.writeText "n8n-task-runners.json" (builtins.toJSON ...)`) in `modules/services/n8n.nix` configuring both `javascript` and `python` task runners with `"TZ"` and `"GENERIC_TIMEZONE"` in `allowed-env` and enforcing the Standard Library Allowlist Invariant ("`/etc/n8n-task-runners.json` in `n8n-runners` MUST set `\"N8N_RUNNERS_STDLIB_ALLOW\": \"*\"` so Python `Code` nodes can import standard library modules (`json`, `datetime`, `re`, `math`, `urllib`, `hashlib`, etc.) without restriction")
- [X] T005 [US1] Configure external task runner settings (`N8N_RUNNERS_ENABLED = "true"`, `N8N_RUNNERS_MODE = "external"`, `N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0"`, `N8N_RUNNERS_BROKER_PORT = "5679"`, `N8N_NATIVE_PYTHON_RUNNER = "true"`) and `environmentFiles = [ "/var/lib/n8n/runners.env" ]` on `virtualisation.oci-containers.containers.n8n` in `modules/services/n8n.nix`
- [X] T006 [US1] Define the `virtualisation.oci-containers.containers.n8n-runners` sidecar container (`image = "docker.io/n8nio/runners:latest"`, `dependsOn = [ "n8n" ]`, `volumes = [ "${taskRunnersConfig}:/etc/n8n-task-runners.json:ro" ]`, `environment.TZ = "Europe/Paris"`, `environment.GENERIC_TIMEZONE = "Europe/Paris"`, `environment.N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679"`, `environmentFiles = [ "/var/lib/n8n/runners.env" ]`, `user = "1000:1000"`) in `modules/services/n8n.nix`

**Checkpoint**: User Story 1 is complete — `n8n` and `n8n-runners` are wired together with Python 3 standard library support and `Europe/Paris` timezone alignment

---

## Phase 4: User Story 2 - Clear Error Reporting and Execution Isolation for Python Scripts (Priority: P2)

**Goal**: Ensure Python `Code` node execution is isolated inside the non-root `n8n-runners` sidecar process with hardened Python flags while keeping the task broker network strictly internal to Podman

**Independent Test**: Evaluate `n8n` and `n8n-runners` container definitions in `modules/services/n8n.nix` to confirm `n8n-runners` publishes zero host ports (`ports = [ ]`), runs as `1000:1000` with `args = [ "-I" "-B" "-X" "disable_remote_debug" "-m" "src.main" ]`, and `n8n` only maps `"127.0.0.1:5679:5678"` on the host loopback interface

### Implementation for User Story 2

- [X] T007 [US2] Verify and enforce process isolation (`user = "1000:1000"`, `args = [ "-I" "-B" "-X" "disable_remote_debug" "-m" "src.main" ]`) and network isolation in `modules/services/n8n.nix`, enforcing the Task Broker Isolation Invariant ("The `n8n` task broker (`N8N_RUNNERS_BROKER_PORT = \"5679\"` inside the `n8n` container) MUST only be reachable on the internal Podman container network (`http://n8n:5679`) and MUST NOT be exposed on external host interfaces. Host loopback `127.0.0.1:5679` continues to map strictly to container web port `5678` for Caddy (`\"127.0.0.1:5679:5678\"`)")

**Checkpoint**: User Story 2 is complete — faulty Python scripts are isolated in the sidecar runner process and task broker traffic remains strictly internal

---

## Phase 5: User Story 3 - Host Availability and Persistence Across Reboots (Priority: P2)

**Goal**: Install `pkgs.python3` system-wide on `homelab` and ensure `podman-n8n` and `podman-n8n-runners` start automatically in the right order after `/persistent` filesystems are mounted

**Independent Test**: Evaluate `.#nixosConfigurations.homelab.config.environment.systemPackages` to confirm `python3` is installed on `homelab`, and evaluate `.#nixosConfigurations.homelab.config.systemd.services.podman-n8n-runners.after` to confirm ordering after `local-fs.target` and `podman-n8n.service`

### Implementation for User Story 3

- [X] T008 [US3] Add `pkgs.python3` to `environment.systemPackages` in `modules/services/n8n.nix`, enforcing the Host Python 3 Availability Invariant ("`pkgs.python3` MUST be present in `environment.systemPackages` on `homelab` so `python3 --version` succeeds in interactive and non-interactive sessions")
- [X] T009 [US3] Configure `systemd.services."podman-n8n-runners".after = [ "local-fs.target" "podman-n8n.service" ]` and verify `/var/lib/n8n` state preservation (`directory = "/var/lib/n8n"`, `user = "1000"`, `group = "1000"`, `mode = "0750"`) in `modules/services/n8n.nix`

**Checkpoint**: User Story 3 is complete — Python 3 is installed on `homelab` and both `podman-n8n` and `podman-n8n-runners` recover automatically across reboots

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Living documentation synchronization (`README.md`), Nix formatting, static linting, multi-host derivation evaluation, and hermetic flake checks

- [X] T010 [P] Update the **Homelab Hosted Services** table in `README.md` to document that `n8n` includes the `n8nio/runners` task runner sidecar for native Python 3 and JavaScript `Code` node execution (Constitution Principle VI)
- [X] T011 [P] Format all Nix files via `just fmt` (`alejandra`) and run static analysis via `just lint` (`statix check`, `deadnix`) on `modules/services/n8n.nix`
- [X] T012 Evaluate NixOS toplevel derivations for `homelab`, `desktop-pc`, and `iso` per `specs/016-add-n8n-python3/quickstart.md`, enforcing the Target Isolation Invariant ("`desktop-pc` and `iso` NixOS configurations MUST remain completely unaffected")
- [X] T013 Run hermetic pre-commit and secret-scanning checks via `just check` (`nix flake check`) across `flake.nix`, `modules/services/n8n.nix`, and `README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — `T001` and `T002` can start immediately in parallel
- **Foundational (Phase 2)**: Depends on Setup completion — `T003` prepares `modules/services/n8n.nix` module arguments and token bootstrap
- **User Stories (Phase 3–5)**: Depend on Foundational phase completion
  - **User Story 1 (P1 - Phase 3)**: Configures `taskRunnersConfig`, `n8n` external runner mode, and `n8n-runners` sidecar container (`T004`–`T006`)
  - **User Story 2 (P2 - Phase 4)**: Verifies process and network isolation invariants on `n8n` and `n8n-runners` (`T007`)
  - **User Story 3 (P2 - Phase 5)**: Adds host `pkgs.python3` and systemd startup ordering for `podman-n8n-runners` (`T008`–`T009`)
- **Polish (Phase 6)**: Depends on Phases 3–5 completion (`T010`–`T013`)

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (`T003`) — delivers the MVP Python 3 `Code` node execution capability in n8n
- **User Story 2 (P2)**: Builds on User Story 1 (`T004`–`T006`) to enforce runner process sandboxing and internal-only task broker networking
- **User Story 3 (P2)**: Can be implemented alongside or immediately after User Story 1 in `modules/services/n8n.nix` to provide host-level `pkgs.python3` and boot ordering

### Parallel Opportunities

- **Phase 1 (Setup)**: `T001` [P] (`modules/services/podman.nix`) and `T002` [P] (`modules/hosts/homelab.nix`, `modules/services/n8n.nix`) inspect separate files and can run in parallel.
- **Phase 6 (Polish)**: `T010` [P] (`README.md`) and `T011` [P] (`just fmt` / `just lint` on `modules/services/n8n.nix`) touch separate files and can run in parallel before `T012` and `T013`.

---

## Parallel Example: Setup & Polish Phases

```bash
# Phase 1: Inspect Podman and homelab/n8n modules in parallel
Task: "T001 [P] Verify Podman OCI container backend and container-to-container DNS resolution in modules/services/podman.nix"
Task: "T002 [P] Verify services.n8n feature composition in modules/hosts/homelab.nix and inspect current container definition in modules/services/n8n.nix"

# Phase 6: Update README.md and format/lint Nix modules in parallel
Task: "T010 [P] Update the Homelab Hosted Services table in README.md to document that n8n includes the n8nio/runners task runner sidecar"
Task: "T011 [P] Format all Nix files via just fmt and run static analysis via just lint on modules/services/n8n.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003` — `pkgs` argument and `runners.env` token bootstrap in `modules/services/n8n.nix`)
3. Complete Phase 3: User Story 1 (`T004`–`T006` — `taskRunnersConfig`, `n8n` external runner mode, and `n8n-runners` sidecar)
4. **STOP and VALIDATE**: Evaluate `homelab` OCI containers configuration to verify `n8n` and `n8n-runners` definitions
5. Complete Phase 4 & Phase 5: User Stories 2 & 3 (`T007`–`T009` — isolation check, host `pkgs.python3`, and systemd `after` ordering)
6. Complete Phase 6: Polish (`T010`–`T013` — `README.md` update, `just fmt`, `just lint`, multi-target evaluation, `just check`)
