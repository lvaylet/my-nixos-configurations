---
description: "Task list for Uptime Kuma monitoring service implementation on homelab"
---

# Tasks: Uptime Kuma Monitoring Service for Homelab

**Input**: Design documents from `/specs/018-add-uptime-kuma/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Not explicitly requested in the feature specification; verification is performed via NixOS derivation evaluation, `quickstart.md` assertions, and `just check` quality gates.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing reverse proxy, domain variable, and port allocation prerequisites

- [X] T001 [P] Verify centralized Caddy reverse proxy and `homelabDomain` (`"homelab.vaylet.fr"`) option in `modules/services/caddy.nix` and `modules/core/vars.nix`
- [X] T002 [P] Verify existing port allocations in `modules/services/waha.nix` (`127.0.0.1:3001`) and `modules/services/adguardhome.nix` (`3000`) to confirm port `3002` availability

---

## Phase 2: Foundational (Module Discovery & Host Wiring)

**Purpose**: Establish the dendritic module skeleton for auto-discovery via `import-tree` and wire `services.uptime-kuma` into `homelab` so each user story phase can be evaluated independently against `.#nixosConfigurations.homelab`

**⚠️ CRITICAL**: Blocking prerequisite for all Uptime Kuma service configuration

- [X] T003 Create dendritic service module skeleton `modules/services/uptime-kuma.nix` exporting `flake.modules.services.uptime-kuma.nixos` (`{ config, lib, vars, ... }: { ... }`)
- [X] T004 Add `services.uptime-kuma` to the `features` list in `modules/hosts/homelab.nix` enforcing `"Adds services.uptime-kuma in alphabetical order between services.tailscale and services.waha"`, `"Must only reference config.flake.modules.*"`, and `"Zero inline service definitions"`

**Checkpoint**: Foundation ready - `uptime-kuma` service module skeleton is discovered automatically by `import-tree` and enabled on `homelab`

---

## Phase 3: User Story 1 - Service Availability Monitoring and Live Status Dashboard (Priority: P1) 🎯 MVP

**Goal**: Enable the native NixOS Uptime Kuma service bound strictly to local loopback `127.0.0.1:3002` so the monitoring engine and dashboard can run health checks across HTTP/HTTPS, TCP, DNS, ping, and TLS certificates

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.services.uptime-kuma.enable` (returns `true`) and `nix eval --json .#nixosConfigurations.homelab.config.services.uptime-kuma.settings` (confirms `"HOST": "127.0.0.1"`, `"PORT": "3002"`, and `"DATA_DIR": "/var/lib/uptime-kuma/"`)

### Implementation for User Story 1

- [X] T005 [US1] Enable native Uptime Kuma service `services.uptime-kuma.enable = true` with `settings.HOST = "127.0.0.1"` and `settings.PORT = "3002"` in `modules/services/uptime-kuma.nix`, enforcing `"Loopback Binding Invariant: services.uptime-kuma.settings.HOST MUST be \"127.0.0.1\" and PORT MUST be \"3002\"; port 3002 MUST NOT be opened in networking.firewall.allowedTCPPorts."`

**Checkpoint**: User Story 1 core monitoring service and loopback listener settings are declared and independently verifiable on `homelab`

---

## Phase 4: User Story 2 - Persistent Monitors, Credentials, and Historical Metrics Across Reboots (Priority: P1)

**Goal**: Configure a static `uptime-kuma` system user/group, disable `DynamicUser`, enforce systemd mount ordering after `local-fs.target`, and preserve `/var/lib/uptime-kuma` under `/persistent` so administrator accounts, monitors, status pages, and heartbeat history survive service restarts and ephemeral root reboots

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.DynamicUser` (`false`), `nix eval .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.User` (`"uptime-kuma"`), and `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` (confirms `/var/lib/uptime-kuma` with `user = "uptime-kuma"`, `group = "uptime-kuma"`, `mode = "0750"`)

### Implementation for User Story 2

- [X] T006 [US2] Declare static system user `users.users.uptime-kuma = { isSystemUser = true; group = "uptime-kuma"; }` and group `users.groups.uptime-kuma = {}` with `systemd.services.uptime-kuma` (`after = [ "local-fs.target" ]`, `serviceConfig = { DynamicUser = lib.mkForce false; User = "uptime-kuma"; Group = "uptime-kuma"; }`) in `modules/services/uptime-kuma.nix`, enforcing `"Mount Order Invariant: systemd.services.uptime-kuma MUST include after = [ \"local-fs.target\" ] to prevent initializing a blank SQLite database in ephemeral tmpfs before /persistent is mounted."`
- [X] T007 [US2] Declare colocated state preservation under `preservation.preserveAt."/persistent".directories` guarded by `lib.mkIf config.services.uptime-kuma.enable` in `modules/services/uptime-kuma.nix`, enforcing `"State Preservation Invariant: /var/lib/uptime-kuma MUST be registered in preservation.preserveAt.\"/persistent\".directories with user = \"uptime-kuma\", group = \"uptime-kuma\", and mode = \"0750\" whenever config.services.uptime-kuma.enable is true, and DynamicUser MUST be forced to false so systemd does not conflict with the bind-mounted directory."`

**Checkpoint**: User Story 2 is functional: `/var/lib/uptime-kuma` is owned by static user `uptime-kuma:uptime-kuma` and preserved across ephemeral root reboots without `DynamicUser` `/var/lib/private` symlink conflicts

---

## Phase 5: User Story 3 - Secure HTTPS Access via Homelab Reverse Proxy (Priority: P1)

**Goal**: Expose Uptime Kuma securely over HTTPS and WebSockets at `uptime.homelab.vaylet.fr` via Caddy while keeping only port `443` open in the firewall

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."uptime.homelab.vaylet.fr".extraConfig` (confirms `reverse_proxy 127.0.0.1:3002`) and confirm `networking.firewall.allowedTCPPorts` includes `443` and excludes `3002`

### Implementation for User Story 3

- [X] T008 [US3] Configure Caddy reverse proxy `services.caddy.enable = true` and `services.caddy.virtualHosts."uptime.${vars.homelabDomain}".extraConfig` with `reverse_proxy 127.0.0.1:3002`, and open HTTPS port via `networking.firewall.allowedTCPPorts = [ 443 ]` in `modules/services/uptime-kuma.nix`

**Checkpoint**: User Story 3 is functional: Uptime Kuma is exposed on `https://uptime.homelab.vaylet.fr` with WebSocket support and loopback isolation on port `3002`

---

## Phase 6: User Story 4 - Outage Alerting and Notification Delivery (Priority: P2)

**Goal**: Verify non-conflicting co-existence and local loopback reachability between Uptime Kuma (`127.0.0.1:3002`), n8n (`127.0.0.1:5679`), and WAHA (`127.0.0.1:3001`) so Uptime Kuma can both monitor internal services and dispatch outbound webhook alerts to homelab automation workflows

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.services.caddy.virtualHosts` and confirm `uptime.homelab.vaylet.fr` (`127.0.0.1:3002`), `waha.homelab.vaylet.fr` (`127.0.0.1:3001`), and `n8n.homelab.vaylet.fr` (`127.0.0.1:5679`) coexist without port collisions

### Implementation for User Story 4

- [X] T009 [US4] Verify non-conflicting port allocations and Caddy virtualHosts across `modules/services/uptime-kuma.nix`, `modules/services/waha.nix`, and `modules/services/n8n.nix`, enforcing `"Port Non-Collision Invariant: Port 3002 avoids conflicts with adguardhome (3000), waha (3001), n8n (5679), portainer (8000, 9443), qbittorrent (8080), filebrowser (8081), jellyfin (8096), and home-automation (8123)."`

**Checkpoint**: User Story 4 is functional: Uptime Kuma coexists cleanly with all homelab services in the host network namespace for monitoring and webhook alerting

---

## Phase 7: User Story 5 - Modular Host Integration and Documentation Synchronization (Priority: P2)

**Goal**: Synchronize `README.md` with the new Uptime Kuma service module, its persistent storage path, and its Caddy reverse proxy endpoint in accordance with Constitution Principle VI

**Independent Test**: Inspect `README.md` and verify that Uptime Kuma appears in the `modules/services/` architecture tree, the Homelab Hosted Services table, and the Reverse Proxy & Secure HTTPS Access table matching `specs/018-add-uptime-kuma/contracts/homelab-host-contract.md`

### Implementation for User Story 5

- [X] T010 [P] [US5] Update `README.md` to add Uptime Kuma to the `modules/services/` architecture tree summary, the Homelab Hosted Services table (`Native Service`, `443 (HTTPS via Caddy)`, `/var/lib/uptime-kuma`), and the Reverse Proxy & Secure HTTPS Access table (`https://uptime.homelab.vaylet.fr` -> `127.0.0.1:3002`, `N/A (loopback bound)`) per `specs/018-add-uptime-kuma/contracts/homelab-host-contract.md`

**Checkpoint**: User Story 5 is functional: `README.md` is 100% synchronized with the live `homelab` service configuration

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, multi-target flake evaluation, and hermetic pre-commit verification

- [X] T011 [P] Format all Nix expressions using `just fmt` (`alejandra`) across `modules/services/uptime-kuma.nix` and `modules/hosts/homelab.nix`
- [X] T012 [P] Run static analysis and dead-code checks via `just lint` (`statix check`, `deadnix`) on `modules/services/uptime-kuma.nix` and `modules/hosts/homelab.nix`
- [X] T013 Verify NixOS toplevel derivation evaluation and target isolation for `homelab`, `desktop-pc`, and `iso` targets per `specs/018-add-uptime-kuma/quickstart.md`, enforcing `"Target Isolation Invariant: Enabling services.uptime-kuma on homelab MUST NOT affect desktop-pc or iso evaluations."`
- [X] T014 Run hermetic pre-commit checks in sandbox via `just check` (`nix flake check`) across `flake.nix`, `README.md`, and all repository files
- [X] T015 Validate all end-to-end evaluation assertions in `specs/018-add-uptime-kuma/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (`T001` and `T002` in parallel)
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories (`T003`–`T004`)
- **User Stories (Phase 3–7)**: Depend on Foundational phase completion
  - **User Story 1 (P1 - Phase 3)**: Depends on Phase 2 (`T005`)
  - **User Story 2 (P1 - Phase 4)**: Depends on US1 (`T006`–`T007`)
  - **User Story 3 (P1 - Phase 5)**: Depends on US1 and US2 (`T008`)
  - **User Story 4 (P2 - Phase 6)**: Depends on US3 (`T009`)
  - **User Story 5 (P2 - Phase 7)**: Can run in parallel with Phase 3–6 since `T010` modifies `README.md`
- **Polish (Phase 8)**: Depends on all user stories (US1–US5) being complete (`T011`–`T015`)

### Parallel Opportunities

- **Phase 1 (Setup)**: `T001` [P] and `T002` [P] inspect independent files (`modules/services/caddy.nix` & `modules/core/vars.nix` vs `modules/services/waha.nix` & `modules/services/adguardhome.nix`) and can run in parallel.
- **Phase 7 (User Story 5)**: `T010` [P] (`README.md`) touches a separate file from `modules/services/uptime-kuma.nix` and `modules/hosts/homelab.nix` and can run in parallel with Nix module implementation.
- **Phase 8 (Polish)**: `T011` [P] (`just fmt`) and `T012` [P] (`just lint`) can run in parallel, and multi-host derivation evaluations in `T013` (`homelab`, `desktop-pc`, `iso`) can run concurrently.

---

## Parallel Example: Setup, Documentation & Polish Phases

```bash
# Phase 1: Verify existing infrastructure in parallel
Task: "T001 [P] Verify centralized Caddy reverse proxy in modules/services/caddy.nix and modules/core/vars.nix"
Task: "T002 [P] Verify existing port allocations in modules/services/waha.nix and modules/services/adguardhome.nix"

# Phase 7: Update README.md in parallel with module implementation
Task: "T010 [P] [US5] Update README.md to add Uptime Kuma to service and reverse proxy tables"

# Phase 8: Run formatting and linting checks in parallel
Task: "T011 [P] Format all Nix expressions using just fmt across modules/services/uptime-kuma.nix and modules/hosts/homelab.nix"
Task: "T012 [P] Run static analysis and dead-code checks via just lint on modules/services/uptime-kuma.nix and modules/hosts/homelab.nix"
```

---

## Implementation Strategy

### MVP First (User Stories 1, 2 & 3 - All P1 Stories)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T004` — `modules/services/uptime-kuma.nix` skeleton + enable in `modules/hosts/homelab.nix`)
3. Complete Phase 3: User Story 1 (`T005` — enable `services.uptime-kuma` on `127.0.0.1:3002`)
4. Complete Phase 4: User Story 2 (`T006`–`T007` — static `uptime-kuma` user/group, `DynamicUser = false`, `/persistent/var/lib/uptime-kuma` preservation)
5. Complete Phase 5: User Story 3 (`T008` — Caddy `uptime.homelab.vaylet.fr` reverse proxy and firewall port `443`)
6. **STOP and VALIDATE**: Evaluate `homelab` configuration and verify service, Caddy virtualHost, firewall, and preservation attributes
7. Complete Phase 6 & 7: User Stories 4 & 5 (`T009`–`T010` — verify co-existence with `n8n`/`waha` and synchronize `README.md`)
8. Complete Phase 8: Polish (`T011`–`T015` — `just fmt`, `just lint`, multi-target eval, `just check`)
