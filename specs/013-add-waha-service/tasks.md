---
description: "Task list for WAHA WhatsApp automation service implementation on homelab"
---

# Tasks: WAHA WhatsApp Automation Service for Homelab

**Input**: Design documents from `/specs/013-add-waha-service/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing container runtime, reverse proxy, and domain variable prerequisites

- [X] T001 [P] Verify Podman OCI container backend and container storage preservation in `modules/services/podman.nix`
- [X] T002 [P] Verify centralized Caddy reverse proxy and `homelabDomain` (`"homelab.vaylet.fr"`) option in `modules/services/caddy.nix` and `modules/core/vars.nix`

---

## Phase 2: Foundational (Module Discovery & Host Wiring)

**Purpose**: Establish the dendritic module skeleton for auto-discovery via `import-tree` and wire `services.waha` into `homelab` so each user story phase can be evaluated independently against `.#nixosConfigurations.homelab`

**⚠️ CRITICAL**: Blocking prerequisite for all WAHA service configuration

- [X] T003 Create dendritic service module skeleton `modules/services/waha.nix` exporting `flake.modules.services.waha.nixos` (`{ config, lib, vars, ... }: { ... }`)
- [X] T004 Add `services.waha` to the `features` list in `modules/hosts/homelab.nix` via `config.flake.modules.services.waha` with zero inline service definitions

**Checkpoint**: Foundation ready - `waha` service module skeleton is discovered automatically by `import-tree` and enabled on `homelab`

---

## Phase 3: User Story 1 - WhatsApp Session Pairing and Automated Messaging for SGDF Activities (Priority: P1) 🎯 MVP

**Goal**: Configure the WAHA OCI container runtime with official image, timezone, and external base URL so the dashboard and API can pair a WhatsApp session and automate SGDF messages

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.image` (returns `"docker.io/devlikeapro/waha:latest"`) and verify `TZ` and `WAHA_BASE_URL` environment variables

### Implementation for User Story 1

- [X] T005 [US1] Configure OCI container definition `virtualisation.oci-containers.containers.waha` in `modules/services/waha.nix` with `image = "docker.io/devlikeapro/waha:latest"`, `environment.TZ = "Europe/Paris"`, and `environment.WAHA_BASE_URL = "https://waha.${vars.homelabDomain}"`

**Checkpoint**: User Story 1 core container image and environment settings are declared and independently verifiable on `homelab`

---

## Phase 4: User Story 2 - Persistent WhatsApp Sessions and Configuration Across Reboots (Priority: P1)

**Goal**: Configure persistent volume mounts, automatic session restoration, systemd mount ordering, and declarative state preservation under `/persistent` so paired WhatsApp sessions survive restarts and ephemeral root reboots without QR code re-scanning

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` and confirm `/var/lib/waha` is preserved with `mode = "0750"`, and verify `WHATSAPP_RESTART_ALL_SESSIONS = "True"` and volume mounts in `virtualisation.oci-containers.containers.waha`

### Implementation for User Story 2

- [X] T006 [US2] Configure persistent volume mounts `volumes = [ "/var/lib/waha/sessions:/app/.sessions" "/var/lib/waha/media:/app/.media" ]` and automatic session reconnection `environment.WHATSAPP_RESTART_ALL_SESSIONS = "True"` in `modules/services/waha.nix`
- [X] T007 [US2] Configure `systemd.services."podman-waha"` with `after = [ "local-fs.target" ]` and `preStart = lib.mkBefore` initializing `/var/lib/waha/sessions`, `/var/lib/waha/media`, and `/var/lib/waha/waha.env` with mode `0600` in `modules/services/waha.nix`
- [X] T008 [US2] Declare colocated state preservation under `preservation.preserveAt."/persistent".directories` with `directory = "/var/lib/waha"` and `mode = "0750"` guarded by `lib.mkIf (config.virtualisation.oci-containers.containers ? waha)` in `modules/services/waha.nix`

**Checkpoint**: User Story 2 is functional: session and media directories are mounted, preserved across ephemeral root reboots, and configured to auto-reconnect

---

## Phase 5: User Story 4 - Secure Reverse Proxy Exposure and Access Control (Priority: P1)

**Goal**: Expose WAHA securely over HTTPS at `waha.homelab.vaylet.fr` via Caddy while binding the container port strictly to loopback (`127.0.0.1:3001:3000`) and loading authentication credentials from `/var/lib/waha/waha.env`

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."waha.homelab.vaylet.fr".extraConfig` (confirms `reverse_proxy 127.0.0.1:3001`), verify container `ports` is `["127.0.0.1:3001:3000"]`, verify `environmentFiles` is `["/var/lib/waha/waha.env"]`, and confirm `networking.firewall.allowedTCPPorts` includes `443` and excludes `3000` and `3001`

### Implementation for User Story 4

- [X] T009 [US4] Configure loopback-only port mapping `ports = [ "127.0.0.1:3001:3000" ]` and persistent secret file loading `environmentFiles = [ "/var/lib/waha/waha.env" ]` on `virtualisation.oci-containers.containers.waha` in `modules/services/waha.nix`
- [X] T010 [US4] Configure Caddy reverse proxy `services.caddy.enable = true` and `services.caddy.virtualHosts."waha.${vars.homelabDomain}".extraConfig` with `reverse_proxy 127.0.0.1:3001`, and open HTTPS port via `networking.firewall.allowedTCPPorts = [ 443 ]` in `modules/services/waha.nix`

**Checkpoint**: User Story 4 is functional: WAHA is exposed on `https://waha.homelab.vaylet.fr`, isolated on loopback port `3001`, and secured via `/var/lib/waha/waha.env`

---

## Phase 6: User Story 3 - Integration with Homelab Workflow Automation (Priority: P2)

**Goal**: Verify non-conflicting co-existence and communication readiness between `services.waha` (`127.0.0.1:3001` / `waha.homelab.vaylet.fr`) and `services.n8n` (`127.0.0.1:5679` / `n8n.homelab.vaylet.fr`) on `homelab`

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.services.caddy.virtualHosts` and confirm both `waha.homelab.vaylet.fr` and `n8n.homelab.vaylet.fr` coexist with distinct loopback upstreams (`127.0.0.1:3001` and `127.0.0.1:5679`)

### Implementation for User Story 3

- [X] T011 [US3] Verify non-conflicting loopback port allocations (`127.0.0.1:3001:3000` vs `127.0.0.1:5679:5678`) and Caddy virtualHosts (`waha.homelab.vaylet.fr` and `n8n.homelab.vaylet.fr`) between `modules/services/waha.nix` and `modules/services/n8n.nix`

**Checkpoint**: User Story 3 is functional: WAHA and n8n coexist cleanly on `homelab` for bi-directional webhook and API automation

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, multi-target flake evaluation, and hermetic pre-commit verification

- [X] T012 [P] Format all Nix expressions using `just fmt` (`alejandra`) across `modules/services/waha.nix` and `modules/hosts/homelab.nix`
- [X] T013 [P] Run static analysis and dead-code checks via `just lint` (`statix check`, `deadnix`) on `modules/services/waha.nix` and `modules/hosts/homelab.nix`
- [X] T014 Verify NixOS toplevel derivation evaluation and target isolation for `homelab`, `desktop-pc`, and `iso` targets per `specs/013-add-waha-service/quickstart.md`
- [X] T015 Run hermetic pre-commit checks in sandbox via `just check` (`nix flake check`) across `flake.nix` and all repository files
- [X] T016 Validate all end-to-end evaluation assertions in `specs/013-add-waha-service/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (`T001` and `T002` in parallel)
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories (`T003`–`T004`)
- **User Stories (Phase 3–6)**: Depend on Foundational phase completion
  - **User Story 1 (P1 - Phase 3)**: Depends on Phase 2 (`T005`)
  - **User Story 2 (P1 - Phase 4)**: Depends on US1 (`T006`–`T008`)
  - **User Story 4 (P1 - Phase 5)**: Depends on US1 and US2 (`T009`–`T010`)
  - **User Story 3 (P2 - Phase 6)**: Depends on US4 (`T011`)
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete (`T012`–`T016`)

### Parallel Opportunities

- **Phase 1 (Setup)**: `T001` [P] and `T002` [P] inspect independent files (`modules/services/podman.nix` vs `modules/services/caddy.nix` and `modules/core/vars.nix`) and can run in parallel.
- **Phase 2 (Foundational)**: `T003` (`modules/services/waha.nix`) and `T004` (`modules/hosts/homelab.nix`) touch separate files and can be prepared together.
- **Phase 7 (Polish)**: `T012` [P] (`just fmt`) and `T013` [P] (`just lint`) can run in parallel, and multi-host derivation evaluations in `T014` (`homelab`, `desktop-pc`, `iso`) can run concurrently.

---

## Parallel Example: Setup & Polish Phases

```bash
# Phase 1: Verify existing infrastructure in parallel
Task: "T001 [P] Verify Podman OCI container backend in modules/services/podman.nix"
Task: "T002 [P] Verify centralized Caddy reverse proxy in modules/services/caddy.nix and modules/core/vars.nix"

# Phase 7: Run formatting and linting checks in parallel
Task: "T012 [P] Format all Nix expressions using just fmt across modules/services/waha.nix and modules/hosts/homelab.nix"
Task: "T013 [P] Run static analysis and dead-code checks via just lint on modules/services/waha.nix and modules/hosts/homelab.nix"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2 & 4 - All P1 Stories)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T004` — `modules/services/waha.nix` skeleton + enable in `modules/hosts/homelab.nix`)
3. Complete Phase 3: User Story 1 (`T005` — OCI container image, timezone, base URL)
4. Complete Phase 4: User Story 2 (`T006`–`T008` — persistent volumes, `preStart`, `/persistent` preservation)
5. Complete Phase 5: User Story 4 (`T009`–`T010` — loopback port, `waha.env`, Caddy `waha.homelab.vaylet.fr`, firewall port `443`)
6. **STOP and VALIDATE**: Evaluate `homelab` configuration and verify container, Caddy virtualHost, firewall, and preservation attributes
7. Complete Phase 6: User Story 3 (`T011` — verify co-existence with `n8n`)
8. Complete Phase 7: Polish (`T012`–`T016` — `just fmt`, `just lint`, multi-target eval, `just check`)
