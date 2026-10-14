---
description: "Task list for secure remote service exposure via Tailscale and Caddy"
---

# Tasks: Secure Remote Service Exposure via Tailscale and Caddy

**Input**: Design documents from `/specs/012-tailscale-caddy-proxy/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing service configurations and prerequisite module declarations

- [X] T001 [P] Verify existing Caddy and Tailscale service modules in `modules/services/caddy.nix` and `modules/services/tailscale.nix`
- [X] T002 [P] Verify existing Home Assistant and n8n service modules in `modules/services/home-automation.nix` and `modules/services/n8n.nix`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Centralized domain identity, Tailscale LocalAPI permissions, and reverse proxy startup ordering

**⚠️ CRITICAL**: Blocking prerequisite for all user stories; must complete before any service proxy can be enabled

- [X] T003 [P] Add `tailscaleDomain` option with default `"tailnet-2900.ts.net"` to `config.flake.vars` in `modules/core/vars.nix`
- [X] T004 [P] Configure `services.tailscale.permitCertUid = "caddy"` to grant certificate fetching permissions in `modules/services/tailscale.nix`
- [X] T005 Configure `systemd.services.caddy.after = [ "local-fs.target" "tailscaled.service" ]` to order Caddy after Tailscale in `modules/services/caddy.nix`

**Checkpoint**: Foundation ready - Caddy is ordered after Tailscale, authorized to fetch certificates, and tailnet domain identity is available globally.

---

## Phase 3: User Story 1 - Secure Remote Access to Home Automation (Priority: P1) 🎯 MVP

**Goal**: Expose Home Assistant over Tailscale with Caddy-managed HTTPS on port 443 with WebSocket streaming

**Independent Test**: Evaluate `nix eval --raw .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."homelab.tailnet-2900.ts.net".extraConfig` (confirms `reverse_proxy 127.0.0.1:8123`) and verify TCP port 443 is in `allowedTCPPorts`

### Implementation for User Story 1

- [X] T006 [US1] Configure Caddy virtualHost for `"${config.networking.hostName}.${config.flake.vars.tailscaleDomain}"` on port 443 with `reverse_proxy 127.0.0.1:8123` in `modules/services/home-automation.nix`
- [X] T007 [US1] Open TCP port 443 alongside existing port 8123 in `networking.firewall.allowedTCPPorts` in `modules/services/home-automation.nix`
- [X] T008 [US1] Document Home Assistant `trusted_proxies` (`127.0.0.1`, `::1`) and `use_x_forwarded_for` configuration requirements in `modules/services/home-automation.nix`

**Checkpoint**: User Story 1 is functional: Home Assistant is accessible over HTTPS at `https://<hostname>.<tailscaleDomain>` on port 443 with WebSocket support.

---

## Phase 4: User Story 2 - Secure Remote Access to Workflow Automation (Priority: P1)

**Goal**: Expose n8n workflow automation over Tailscale with Caddy-managed HTTPS on port 5678 and loopback isolation

**Independent Test**: Evaluate `nix eval --raw .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."homelab.tailnet-2900.ts.net:5678".extraConfig` (confirms `reverse_proxy 127.0.0.1:5679`) and verify container port mapping is restricted to `127.0.0.1:5679:5678`

### Implementation for User Story 2

- [X] T009 [US2] Update Caddy virtualHost in `modules/services/n8n.nix` to `"${config.networking.hostName}.${config.flake.vars.tailscaleDomain}:5678"` with `reverse_proxy 127.0.0.1:5679` replacing internal CA configuration
- [X] T010 [US2] Restrict n8n container port mapping strictly to loopback interface `"127.0.0.1:5679:5678"` in `modules/services/n8n.nix`
- [X] T011 [US2] Ensure inbound TCP port 5678 is permitted in `networking.firewall.allowedTCPPorts` in `modules/services/n8n.nix`

**Checkpoint**: User Story 2 is functional: n8n is accessible over HTTPS at `https://<hostname>.<tailscaleDomain>:5678` with genuine Tailscale TLS and loopback container isolation.

---

## Phase 5: User Story 3 - Automated and Trusted TLS Certificate Lifecycle (Priority: P1)

**Goal**: Ensure certificate persistence across ephemeral root reboots, verify Tailscale LocalAPI permissions, and avoid read-only trust store failures

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` and verify `/var/lib/caddy` is preserved with user `caddy` and group `caddy`

### Implementation for User Story 3

- [X] T012 [US3] Verify declarative state preservation for directory `"/var/lib/caddy"` with `user = "caddy"`, `group = "caddy"`, and `mode = "0750"` under `preservation.preserveAt."/persistent".directories` in `modules/services/caddy.nix`
- [X] T013 [US3] Ensure `globalConfig` preserves `skip_install_trust` and `auto_https disable_redirects` in `modules/services/caddy.nix` to avoid read-only `/etc` trust store write failures while allowing Tailscale certificate fetching

**Checkpoint**: User Story 3 is functional: TLS certificates and keys persist across reboots under `/persistent` without read-only filesystem errors.

---

## Phase 6: User Story 4 - Standardized and Extensible Service Proxying (Priority: P2)

**Goal**: Verify consistent header forwarding, streaming behavior, and dendritic service isolation for extensible proxying

**Independent Test**: Review proxy routing contracts and ensure Home Assistant and n8n proxy configurations adhere to the standard dendritic pattern

### Implementation for User Story 4

- [X] T014 [US4] Verify reverse proxy WebSocket streaming and client header forwarding behavior in `modules/services/home-automation.nix` and `modules/services/n8n.nix`
- [X] T015 [US4] Document dendritic reverse proxy pattern and guidelines for future services in `specs/012-tailscale-caddy-proxy/contracts/service-endpoints-contract.md`

**Checkpoint**: User Story 4 is functional: reverse proxy architecture is standardized, extensible, and fully documented.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, multi-target flake evaluation, and pre-commit verification

- [X] T016 [P] Format all Nix expressions using `just fmt` (`alejandra`)
- [X] T017 [P] Run static analysis and dead code lint checks via `just lint` (`statix check`, `deadnix`)
- [X] T018 Validate NixOS toplevel derivation evaluation for `homelab`, `desktop-pc`, and `iso` targets per `specs/012-tailscale-caddy-proxy/quickstart.md`
- [X] T019 Run hermetic pre-commit checks in sandbox via `just check` (`nix flake check`)
- [X] T020 Validate all end-to-end quickstart scenarios in `specs/012-tailscale-caddy-proxy/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
  - **User Story 1 (P1)**: Depends on Phase 2 - Implements Home Assistant HTTPS proxy (MVP)
  - **User Story 2 (P1)**: Depends on Phase 2 - Implements n8n HTTPS proxy
  - **User Story 3 (P1)**: Depends on Phase 2 - Verifies certificate persistence and Caddy globalConfig
  - **User Story 4 (P2)**: Depends on US1 and US2 - Validates proxy consistency and documents extensibility
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete

### Parallel Opportunities

- In Phase 1: `T001` [P] and `T002` [P] can run in parallel.
- In Phase 2: `T003` [P] and `T004` [P] can run in parallel.
- Once Phase 2 completes, User Story 1 (`T006`–`T008`), User Story 2 (`T009`–`T011`), and User Story 3 (`T012`–`T013`) can be implemented in parallel across separate files.
- In Phase 7: `T016` [P] and `T017` [P] can run in parallel.

---

## Parallel Example: User Story 1 & User Story 2

```bash
# Implement User Story 1 and User Story 2 concurrently in separate service files:
Task: "T006 [US1] Configure Caddy virtualHost in modules/services/home-automation.nix"
Task: "T009 [US2] Update Caddy virtualHost in modules/services/n8n.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`modules/services/caddy.nix`, `tailscale.nix`, `home-automation.nix`, `n8n.nix` inspection)
2. Complete Phase 2: Foundational (`modules/core/vars.nix`, `modules/services/tailscale.nix`, `modules/services/caddy.nix`)
3. Complete Phase 3: User Story 1 (Home Assistant HTTPS proxy on port 443 in `modules/services/home-automation.nix`)
4. **STOP and VALIDATE**: Verify `homelab` evaluates with Home Assistant Caddy virtualHost and port 443
5. Complete Phase 4: User Story 2 (n8n proxy on port 5678 in `modules/services/n8n.nix`)
6. Complete Phase 5: User Story 3 (Caddy persistence in `modules/services/caddy.nix`)
7. Complete Phase 6: User Story 4 (Extensibility validation & contract documentation)
8. Complete Phase 7: Polish (Format, lint, evaluation, pre-commit checks)
