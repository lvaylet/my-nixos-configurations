---

description: "Task list for securing Portainer and Home Assistant network exposure and container privileges"
---

# Tasks: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Input**: Design documents from `/specs/025-secure-portainer-homeassistant/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/portainer-homeassistant-security-contract.md, quickstart.md

**Tests**: Standalone test suites are not requested; verification is performed via hermetic Nix evaluation (`nix eval`), static analysis (`just lint`), formatting checks (`just fmt`), and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dedicated branch isolation per Constitution Principle VII.

- [X] T001 Create and switch to dedicated feature branch `025-secure-portainer-homeassistant` from `main` in repository root `.git`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — `services.portainer`, `services.home-automation`, `services.caddy`, `services.podman`, and `core.preservation` are already wired in `modules/hosts/homelab.nix`.)*

---

## Phase 3: User Story 1 - Restrict Portainer to Localhost Reverse Proxy Without Privileged Mode (Priority: P1) 🎯 MVP

**Goal**: Restrict Portainer port binding to `127.0.0.1:9443:9443`, remove unused port `8000`, remove `extraOptions = ["--privileged"]`, and remove `networking.firewall.allowedTCPPorts = [8000 9443]` in `modules/services/portainer.nix`.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.ports`, `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.extraOptions`, and `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts` via `nix eval` to confirm `ports` equals `["127.0.0.1:9443:9443"]`, `extraOptions` equals `[]`, and `8000`/`9443` are absent from `allowedTCPPorts`.

### Implementation for User Story 1

- [X] T002 [P] [US1] Update `modules/services/portainer.nix` to set `ports = ["127.0.0.1:9443:9443"]`, remove `extraOptions = ["--privileged"]`, and remove `networking.firewall.allowedTCPPorts = [8000 9443]` per `specs/025-secure-portainer-homeassistant/contracts/portainer-homeassistant-security-contract.md`
- [X] T003 [US1] Verify `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.ports` (`["127.0.0.1:9443:9443"]`), `extraOptions` (`[]`), and absence of `8000`/`9443` in `networking.firewall.allowedTCPPorts` via `nix eval` against `modules/services/portainer.nix`

**Checkpoint**: User Story 1 complete — Portainer listens strictly on `127.0.0.1:9443`, runs without `--privileged`, and does not open ports `8000` or `9443` in the host firewall.

---

## Phase 4: User Story 2 - Restrict Home Assistant to Encrypted Reverse Proxy Access (Priority: P1)

**Goal**: Remove `networking.firewall.allowedTCPPorts = [443 8123]` from `modules/services/home-automation.nix` so that redundant port `443` is managed centrally by `modules/services/caddy.nix` and unencrypted LAN HTTP access on port `8123` is blocked by the host firewall while retaining `--network=host` for local discovery.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts` and `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.homeassistant.extraOptions` via `nix eval` to confirm port `8123` is absent, port `443` remains present, and `--network=host` is preserved.

### Implementation for User Story 2

- [X] T004 [P] [US2] Remove `networking.firewall.allowedTCPPorts = [443 8123]` from `modules/services/home-automation.nix` while preserving `--network=host` and `services.caddy.virtualHosts."ha.${vars.homelabDomain}"` per `specs/025-secure-portainer-homeassistant/contracts/portainer-homeassistant-security-contract.md`
- [X] T005 [US2] Verify via `nix eval` against `modules/services/home-automation.nix` that `8123` is absent from `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts`, `443` remains present, and `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.homeassistant.extraOptions` equals `["--network=host"]`

**Checkpoint**: User Story 2 complete — Home Assistant is no longer exposed on TCP port `8123` across the LAN firewall and routes external client traffic exclusively via Caddy HTTPS on port `443`.

---

## Phase 5: User Story 3 - Synchronized Service and Setup Documentation (Priority: P2)

**Goal**: Update `README.md` service tables, reverse proxy tables, and Home Assistant reverse proxy setup instructions (including dual-shell Bash/Fish SSH port forwarding commands) to reflect the hardened network configuration.

**Independent Test**: Inspect `README.md` (`Homelab Hosted Services`, `Reverse Proxy & Secure HTTPS Access`, and `3. Home Assistant Reverse Proxy Authorization (UI Configuration)`) to confirm ports `8000`, `9443`, and `8123` are removed from exposed network ports, `LAN Direct URL` is `N/A (loopback bound)` for both services, and SSH tunnel instructions provide explicit Bash and Fish variants.

### Implementation for User Story 3

- [X] T006 [P] [US3] Update `README.md` (`Homelab Hosted Services` table, `Reverse Proxy & Secure HTTPS Access` table, and `3. Home Assistant Reverse Proxy Authorization (UI Configuration)`) with loopback-only port mappings and dual-shell (Bash/Fish) SSH port-forwarding instructions per `specs/025-secure-portainer-homeassistant/contracts/portainer-homeassistant-security-contract.md`

**Checkpoint**: User Story 3 complete — `README.md` is synchronized with the hardened Portainer and Home Assistant configuration.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute all repository quality gates, formatters, static linters, and full flake checks.

- [X] T007 [P] Format Nix files (`just fmt`) and run static analysis (`just lint`) across `modules/services/portainer.nix`, `modules/services/home-automation.nix`, and `README.md`
- [X] T008 Run full hermetic sandbox check (`just check`) and validate all evaluation commands in `specs/025-secure-portainer-homeassistant/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Must complete first (`T001`) so all work is isolated on branch `025-secure-portainer-homeassistant`.
- **User Story 1 (Phase 3)**: Starts after `T001` (`T002` → `T003`).
- **User Story 2 (Phase 4)**: Starts after `T001` (`T004` → `T005`); touches `modules/services/home-automation.nix` and can run in parallel with US1 and US3.
- **User Story 3 (Phase 5)**: Starts after `T001` (`T006`); touches `README.md` and can run in parallel with US1 and US2.
- **Polish (Phase 6)**: Depends on completion of Phases 3, 4, and 5 (`T007` → `T008`).

### User Story Dependencies

- **User Story 1 (P1)**: Independent MVP — hardens `modules/services/portainer.nix`.
- **User Story 2 (P1)**: Independent security hardening in `modules/services/home-automation.nix`.
- **User Story 3 (P2)**: Independent documentation synchronization in `README.md`.

### Parallel Opportunities

- `T002` (`modules/services/portainer.nix`), `T004` (`modules/services/home-automation.nix`), and `T006` (`README.md`) modify completely separate files and can be executed in parallel.
- `T003` and `T005` are read-only `nix eval` verification tasks that can run in parallel after `T002` and `T004`.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# 1. Execute module and documentation edits in parallel across separate files:
Task T002: "Update modules/services/portainer.nix (127.0.0.1:9443:9443, remove --privileged, remove firewall 8000/9443)"
Task T004: "Update modules/services/home-automation.nix (remove firewall 443/8123)"
Task T006: "Update README.md tables and Home Assistant SSH tunnel bootstrap instructions"

# 2. Run read-only nix eval verifications in parallel:
Task T003: "Verify Portainer container ports, extraOptions, and firewall rules via nix eval"
Task T005: "Verify Home Assistant firewall rules and extraOptions via nix eval"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1: Setup (`T001`).
2. Complete Phase 3: User Story 1 (`T002`, `T003`) to harden Portainer network exposure and container privileges.
3. Complete Phase 4: User Story 2 (`T004`, `T005`) to harden Home Assistant firewall rules.
4. Complete Phase 5: User Story 3 (`T006`) to synchronize `README.md`.
5. Complete Phase 6: Polish (`T007`, `T008`) with `just fmt`, `just lint`, and `just check`.
