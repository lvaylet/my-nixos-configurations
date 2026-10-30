---
description: "Task list for Remote Web Code Editor on Homelab"
---

# Tasks: Remote Web Code Editor on Homelab

**Input**: Design documents from `/specs/035-web-code-editor/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/code-server-service-contract.md`, `contracts/homelab-host-contract.md`, `quickstart.md`

**Tests**: Tests are not requested as standalone unit suites; validation is performed through hermetic flake evaluation (`nix eval`), static linters (`deadnix`, `statix`), `quickstart.md` verification scenarios, and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify dependencies, available loopback port allocations, and reverse proxy variables for `code-server`

- [X] T001 Verify `code-server` package availability in nixpkgs and validate `services.code-server` options on `homelab` via `nix eval`
- [X] T002 [P] Verify port `4444` loopback availability against existing service allocations in `modules/services/` (`3001` waha, `3002` uptime-kuma, `4096` opencode, `5679` n8n, `8000` sgdf-utils, `8080` qbittorrent, `8081` filebrowser, `8096` jellyfin, `8123` ha, `9443` portainer)
- [X] T003 [P] Verify centralized Caddy reverse proxy integration and `vars.homelabDomain` (`"homelab.vaylet.fr"`) option in `modules/services/caddy.nix` and `modules/core/vars.nix`

---

## Phase 2: Foundational (Module Skeleton & Host Wiring)

**Purpose**: Create the dendritic module skeleton for auto-discovery via `import-tree` and wire `services.code-server` into `homelab` so subsequent story tasks evaluate cleanly against `.#nixosConfigurations.homelab`

**⚠️ CRITICAL**: Must be completed before any user story implementation can begin

- [X] T004 Create dendritic service module skeleton in `modules/services/code-server.nix` declaring `flake.modules.services.code-server` with `nixos` definition per `specs/035-web-code-editor/contracts/code-server-service-contract.md`
- [X] T005 Add `services.code-server` to the `features` list in `modules/hosts/homelab.nix` in alphabetical order between `services.caddy` and `services.filebrowser`, enforcing `"Zero inline service definitions"` per Constitution Principle II

**Checkpoint**: Foundation ready — `modules/services/code-server.nix` is discovered by `import-tree` and enabled on `homelab`.

---

## Phase 3: User Story 1 - Remote Code Viewing and Editing via Web Browser (Priority: P1) 🎯 MVP

**Goal**: Make `code-server` operational on `homelab` running as unprivileged user `laurent:users` bound to loopback port `4444` with authentication delegated to Tailscale (`auth = "none"`).

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.services.code-server.enable` (true), verify `user = "laurent"`, `group = "users"`, `host = "127.0.0.1"`, `port = 4444`, and `auth = "none"`.

### Implementation for User Story 1

- [X] T006 [P] [US1] Configure core `services.code-server` options (`enable = true`, `user = vars.userName`, `group = "users"`, `host = "127.0.0.1"`, `port = 4444`) in `modules/services/code-server.nix`
- [X] T007 [P] [US1] Configure privacy and update settings (`disableTelemetry = true`, `disableUpdateCheck = true`) on `services.code-server` in `modules/services/code-server.nix`
- [X] T008 [US1] Set `auth = "none"` on `services.code-server` in `modules/services/code-server.nix`, delegating access control to Tailscale network isolation per `specs/035-web-code-editor/contracts/code-server-service-contract.md`
- [X] T009 [US1] Verify basic `code-server` derivation evaluation on `homelab` with `nix eval .#nixosConfigurations.homelab.config.systemd.services.code-server.serviceConfig.ExecStart`

**Checkpoint**: User Story 1 is functional: `code-server` daemon is configured to run on loopback port 4444 without password prompt for authorized tailnet users.

---

## Phase 4: User Story 2 - Integrated Terminal and Workspace Tools (Priority: P2)

**Goal**: Configure the default workspace root to `/home/laurent` and expose development tools (`bash`, `git`, `just`, `nh`, `nix`, `nixos-rebuild`, `ripgrep`, `direnv`) in the integrated terminal's `PATH`.

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.services.code-server.extraArguments` to confirm `[ "/home/laurent" ]`, and evaluate `services.code-server.extraPackages` to confirm inclusion of `git`, `just`, and `nix`.

### Implementation for User Story 2

- [X] T010 [P] [US2] Configure initial workspace root `extraArguments = [ "/home/${vars.userName}" ]` in `modules/services/code-server.nix` so the editor launches focused on `/home/laurent`
- [X] T011 [P] [US2] Configure development packages in `services.code-server.extraPackages` in `modules/services/code-server.nix` including `bash`, `coreutils`, `direnv`, `git`, `just`, `nh`, `nix`, `nixos-rebuild`, and `ripgrep`
- [X] T012 [US2] Verify environment and workspace configuration by evaluating `.#nixosConfigurations.homelab.config.systemd.services.code-server.environment.PATH` and command line arguments

**Checkpoint**: User Story 2 is functional: `code-server` opens `/home/laurent` with the full Nix development toolchain available inside the integrated terminal.

---

## Phase 5: User Story 3 - Secure Remote Exposure and TLS Integration (Priority: P3)

**Goal**: Expose `code-server` over HTTPS at `https://code.homelab.vaylet.fr` via centralized Caddy reverse proxy with automatic Cloudflare DNS-01 TLS certificate provisioning.

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."code.homelab.vaylet.fr".extraConfig` to verify `reverse_proxy 127.0.0.1:4444`, and verify port 443 is permitted in firewall.

### Implementation for User Story 3

- [X] T013 [US3] Configure Caddy virtual host `services.caddy.virtualHosts."code.${vars.homelabDomain}"` with `reverse_proxy 127.0.0.1:4444` in `modules/services/code-server.nix`, guarded by `lib.mkIf config.services.caddy.enable`
- [X] T014 [US3] Verify Caddy virtual host configuration and port 443 firewall access by evaluating `.#nixosConfigurations.homelab.config.services.caddy.virtualHosts."code.homelab.vaylet.fr".extraConfig`

**Checkpoint**: User Story 3 is functional: `code-server` is reverse-proxied over HTTPS at `https://code.homelab.vaylet.fr` via Caddy.

---

## Phase 6: User Story 4 - Ephemeral Boot Persistence and Service Continuity (Priority: P4)

**Goal**: Preserve `code-server` user data, extensions, and configuration across reboots on `homelab`'s ephemeral `tmpfs` root, and ensure systemd starts the service only after local filesystems are mounted.

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".users.laurent.directories` to verify `".local/share/code-server"` and `".config/code-server"` are registered, and verify `systemd.services.code-server.after` includes `[ "network.target" "local-fs.target" ]`.

### Implementation for User Story 4

- [X] T015 [US4] Configure `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/services/code-server.nix` for `".local/share/code-server"` and `".config/code-server"`, guarded by `lib.mkIf config.services.caddy.enable`
- [X] T016 [US4] Configure `systemd.services.code-server` unit dependencies in `modules/services/code-server.nix` ensuring `after = [ "network.target" "local-fs.target" ]` and `restartSec = 5`
- [X] T017 [US4] Verify preservation configuration on `homelab` by evaluating `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".users.laurent.directories`

**Checkpoint**: User Story 4 is functional: All extensions, user preferences, and workspace state survive reboots on `homelab`'s ephemeral root.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Synchronize living documentation with dual Bash/Fish parity, format code, and verify all quality gates

- [X] T018 [P] Update `README.md` to document `code-server` in Architecture Overview, Hosted Services table (port `4444`), Reverse Proxy Endpoints table (`https://code.homelab.vaylet.fr`), and Remote Development section with explicit **Bash** and **Fish** code blocks per Constitution Principle VI
- [X] T019 Format all Nix files with `just fmt` (`alejandra`) and verify zero formatting diffs per Constitution Principle III
- [X] T020 Run static analysis with `just lint` (`statix`, `deadnix`) with zero warnings or errors per Constitution Principle III
- [X] T021 Execute hermetic sandbox checks with `just check` (`nix flake check`) and verify exit code 0 per Constitution Principle V
- [X] T022 Run quickstart verification scenarios per `specs/035-web-code-editor/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - **User Story 1 (P1)**: Core daemon service definition (`code-server`)
  - **User Story 2 (P2)**: Workspace directory and PATH toolchain (builds on US1)
  - **User Story 3 (P3)**: Caddy reverse proxy endpoint (builds on US1/US2)
  - **User Story 4 (P4)**: State preservation and boot order (builds on US1)
- **Polish (Phase 7)**: Depends on all user story tasks being complete

---

## Parallel Opportunities

- **Phase 1 (Setup)**: Tasks T002 and T003 can execute in parallel.
- **Phase 3 (User Story 1)**: Tasks T006 and T007 can execute in parallel.
- **Phase 4 (User Story 2)**: Tasks T010 and T011 can execute in parallel.
- **Phase 7 (Polish)**: Task T018 (`README.md`) can be prepared in parallel with code validation.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup: verify port and options).
2. Complete Phase 2 (Foundational: create skeleton in `modules/services/code-server.nix` and add to `homelab.nix`).
3. Complete Phase 3 (User Story 1: configure core service and evaluate derivation).
4. **STOP and VALIDATE**: Confirm `code-server` evaluates cleanly on `homelab`.

### Incremental Delivery

1. Foundation ready (`modules/services/code-server.nix` linked in `homelab.nix`).
2. Add US1 (`code-server` daemon configured with `auth = "none"`).
3. Add US2 (Workspace set to `/home/laurent`, development packages added).
4. Add US3 (Caddy reverse proxy configured for `code.homelab.vaylet.fr`).
5. Add US4 (Preservation directories registered under `/persistent/home/laurent`).
6. Polish (`README.md` updated with dual-shell instructions, `just fmt`, `just lint`, `just check`).
