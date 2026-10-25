---
description: "Task list for OpenCode v2 on homelab with shared configuration and web access"
---

# Tasks: OpenCode v2 on Homelab with Shared Configuration and Web Access

**Input**: Design documents from `/specs/022-add-opencode-homelab/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/opencode-service-contract.md`, `contracts/homelab-host-contract.md`, `quickstart.md`

**Tests**: Tests are not requested as standalone unit suites; validation is performed through hermetic flake evaluation (`nix eval`), static linters (`deadnix`, `statix`), `quickstart.md` verification scenarios, and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Declare the OpenCode v2 flake input and verify infrastructure prerequisites (reverse proxy and port allocations)

- [X] T001 Add `inputs.opencode` (`github:anomalyco/opencode/v2.1.4` with `inputs.nixpkgs.follows = "nixpkgs"`) in `flake.nix` and update `flake.lock`
- [X] T002 [P] Verify centralized Caddy reverse proxy, DNS-01 provider, and `homelabDomain` (`"homelab.vaylet.fr"`) option in `modules/services/caddy.nix` and `modules/core/vars.nix`
- [X] T003 [P] Verify port `4096` loopback availability against existing service allocations in `modules/services/waha.nix` (port 3001), `modules/services/uptime-kuma.nix` (port 3002), and `modules/services/n8n.nix` (port 5679)

---

## Phase 2: Foundational (Module Skeleton & Host Wiring)

**Purpose**: Create the dendritic module skeleton for auto-discovery via `import-tree` and wire `services.opencode` into `homelab` so subsequent story tasks evaluate cleanly against `.#nixosConfigurations.homelab`

**⚠️ CRITICAL**: Must be completed before any user story implementation can begin

- [X] T004 Create dendritic service module skeleton in `modules/services/opencode.nix` declaring `flake.modules.services.opencode` with `nixos`, `homeManager`, and `darwin` definitions per `specs/022-add-opencode-homelab/contracts/opencode-service-contract.md`
- [X] T005 Add `services.opencode` to the `features` list in `modules/hosts/homelab.nix` in alphabetical order between `services.nix-ld` and `services.podman`, enforcing `"Must only reference config.flake.modules.*"` and `"Zero inline service definitions"` per Constitution Principle II

**Checkpoint**: Foundation ready — `modules/services/opencode.nix` is discovered by `import-tree` and enabled on `homelab`.

---

## Phase 3: User Story 1 - Interactive OpenCode Shell Environment on `homelab` (Priority: P1) 🎯 MVP

**Goal**: Make OpenCode v2 available directly in the shell environment on `homelab` for interactive terminal use by the primary user (`laurent`) with declarative user configuration.

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.environment.systemPackages` to confirm presence of OpenCode v2 package derivation, and verify `systemd.tmpfiles.rules` provisions `/home/laurent/.config/opencode/opencode.json` with user permissions.

### Implementation for User Story 1

- [X] T006 [P] [US1] Add OpenCode v2 package (`inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode`) to `environment.systemPackages` in `modules/services/opencode.nix` so the `opencode` binary is available in `$PATH` on `homelab`
- [X] T007 [P] [US1] Configure declarative user configuration at `/home/${vars.userName}/.config/opencode/opencode.json` via `systemd.tmpfiles.rules` in `modules/services/opencode.nix` setting `theme = "nord"` and mode `0755 laurent users`
- [X] T008 [US1] Verify shell CLI execution and configuration parsing by evaluating `.#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`

**Checkpoint**: User Story 1 is functional: OpenCode v2 is available as an interactive terminal command on `homelab` with the Nord theme.

---

## Phase 4: User Story 2 - Shared and Mutualized OpenCode Configuration Across Machines (Priority: P2)

**Goal**: Centralize and mutualize OpenCode settings across all machines (`desktop-pc`, `macbook-air-m4-15`, `homelab`) so that all hosts share OpenCode v2 and the Nord theme without duplicated inline settings.

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.opencode.tui.theme` (`"nord"`) and `nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.opencode.tui.theme` (`"nord"`), verifying both workstations consume the shared module.

### Implementation for User Story 2

- [X] T009 [P] [US2] Implement shared `homeManager` configuration in `modules/services/opencode.nix` configuring `programs.opencode.enable = true`, `package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode`, and `tui.theme = "nord"`
- [X] T010 [P] [US2] Implement shared `darwin` configuration in `modules/services/opencode.nix` exposing OpenCode v2 package for macOS
- [X] T011 [US2] Refactor `modules/desktop/apps.nix` to remove the redundant inline `opencode = { enable = true; tui.theme = "nord"; };` block in favor of the shared `services.opencode` module
- [X] T012 [US2] Add `services.opencode` to `modules/hosts/desktop-pc.nix` and `modules/hosts/macbook-air-m4-15.nix` in `features` (in alphabetical order) and verify multi-target flake evaluation across all hosts

**Checkpoint**: User Story 2 is functional: OpenCode v2 and Nord theme configuration are centralized in a single module shared across Linux and macOS targets.

---

## Phase 5: User Story 3 - Browser Access and HTTPS Exposure via `opencode.homelab.vaylet.fr` (Priority: P3)

**Goal**: Run a headless OpenCode v2 daemon on `homelab` bound strictly to `127.0.0.1:4096` with runtime authentication, exposed externally at `https://opencode.homelab.vaylet.fr` via Caddy reverse proxy with automatic TLS.

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.systemd.services.opencode-web.serviceConfig.ExecStart` (confirms `serve --hostname 127.0.0.1 --port 4096`), `nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."opencode.homelab.vaylet.fr".extraConfig` (confirms `reverse_proxy 127.0.0.1:4096`), and verify `networking.firewall.allowedTCPPorts` allows `443` and does not expose `4096`.

### Implementation for User Story 3

- [X] T013 [P] [US3] Declare dedicated system user `users.users.opencode = { isSystemUser = true; group = "opencode"; }` and group `users.groups.opencode = {}` in `modules/services/opencode.nix`
- [X] T014 [P] [US3] Configure `systemd.services.opencode-web` in `modules/services/opencode.nix` with `ExecStart = "${opencodePackage}/bin/opencode serve --hostname 127.0.0.1 --port 4096"`, `WorkingDirectory = "/var/lib/opencode"`, `User = "opencode"`, `Group = "opencode"`, `Restart = "always"`, `RestartSec = 5`, and `EnvironmentFile = "-/var/lib/opencode/opencode.env"`
- [X] T015 [US3] Implement `preStart` script on `systemd.services.opencode-web` in `modules/services/opencode.nix` to initialize `/var/lib/opencode` (`0750`) and generate a random `OPENCODE_SERVER_PASSWORD` in `opencode.env` (`0600`) if missing, enforcing `"Secret Hygiene Invariant: Plaintext passwords MUST NEVER appear in Nix expressions, Nix store paths, or Git commits. The password file MUST have file mode 0600 and be owned by opencode:opencode."`
- [X] T016 [US3] Configure Caddy virtual host `services.caddy.virtualHosts."opencode.${vars.homelabDomain}"` with `reverse_proxy 127.0.0.1:4096` in `modules/services/opencode.nix`, opening port `443` in the firewall and enforcing `"Loopback Isolation Invariant: The daemon MUST NOT listen on 0.0.0.0 or public network interfaces; all external traffic MUST route through Caddy reverse proxy on port 443."`

**Checkpoint**: User Story 3 is functional: OpenCode web server daemon runs under systemd on loopback port 4096 and is reverse-proxied with automatic TLS by Caddy at `https://opencode.homelab.vaylet.fr`.

---

## Phase 6: User Story 4 - Session Persistence and Operational Continuity Across Reboots (Priority: P4)

**Goal**: Preserve OpenCode state, database, and credentials across system reboots on `homelab`'s ephemeral `tmpfs` root, and ensure systemd starts the service only after `/persistent` is mounted.

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` to verify `/var/lib/opencode` is registered with `user = "opencode"`, `group = "opencode"`, and `mode = "0750"`, and verify `systemd.services.opencode-web.after` includes `[ "network.target" "local-fs.target" ]`.

### Implementation for User Story 4

- [X] T017 [US4] Configure `preservation.preserveAt."/persistent".directories` in `modules/services/opencode.nix` for `/var/lib/opencode` with `user = "opencode"`, `group = "opencode"`, and `mode = "0750"`, enforcing `"State Preservation Invariant: /var/lib/opencode MUST be registered in preservation.preserveAt.\"/persistent\".directories with user = \"opencode\", group = \"opencode\", and mode = \"0750\"."`
- [X] T018 [US4] Ensure `systemd.services.opencode-web` ordering includes `after = [ "network.target" "local-fs.target" ]` in `modules/services/opencode.nix` to prevent service startup before `/persistent` bind mounts are established

**Checkpoint**: User Story 4 is functional: All OpenCode state, sessions, database, and credentials survive reboots on `homelab`'s ephemeral root.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Synchronize living documentation with dual Bash/Fish parity, format code, and verify all quality gates

- [X] T019 [P] Update `README.md` to document OpenCode v2 in Architecture Overview, Hosted Services table (port `4096`), and Reverse Proxy Endpoints table (`https://opencode.homelab.vaylet.fr`), providing explicit **Bash** and **Fish** operational code blocks per Constitution Principle VI
- [X] T020 Format all Nix files with `just fmt` (`alejandra`) and verify zero formatting diffs per Constitution Principle III
- [X] T021 Run static analysis with `just lint` (`statix`, `deadnix`) with zero warnings or errors per Constitution Principle III
- [X] T022 Execute hermetic sandbox checks with `just check` (`nix flake check`) and verify exit code 0 per Constitution Principle V
- [X] T023 Run quickstart verification scenarios per `specs/022-add-opencode-homelab/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) — BLOCKS all user stories
- **User Story 1 (Phase 3, P1)**: Depends on Foundational (Phase 2) — Core MVP
- **User Story 2 (Phase 4, P2)**: Depends on Foundational (Phase 2) and US1 package definitions — can integrate with US1
- **User Story 3 (Phase 5, P3)**: Depends on Foundational (Phase 2) and US1 package definitions
- **User Story 4 (Phase 6, P4)**: Depends on US3 service declarations
- **Polish (Phase 7)**: Depends on all user stories being implemented

### User Story Completion Order

```text
Phase 1: Setup (T001-T003)
       │
       ▼
Phase 2: Foundational (T004-T005)
       │
       ├────────────────────────┐
       ▼                        ▼
Phase 3: US1 - CLI on homelab   Phase 4: US2 - Multi-host Config
(T006-T008) [MVP]              (T009-T012)
       │                        │
       ▼                        │
Phase 5: US3 - Web & Caddy      │
(T013-T016)                     │
       │                        │
       ▼                        │
Phase 6: US4 - Persistence      │
(T017-T018)                     │
       │                        │
       ▼                        ▼
Phase 7: Polish & Quality Gates (T019-T023)
```

---

## Parallel Execution Opportunities

- **Phase 1 (Setup)**: T002 (`caddy.nix`) and T003 (port allocations) can run in parallel.
- **Phase 3 (User Story 1)**: T006 (system package) and T007 (user tmpfiles config) can run in parallel.
- **Phase 4 (User Story 2)**: T009 (homeManager config) and T010 (darwin config) can run in parallel.
- **Phase 5 (User Story 3)**: T013 (user/group) and T014 (systemd service) can run in parallel.
- **Phase 7 (Polish)**: T019 (`README.md` documentation) can run in parallel with early tasks.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (add `inputs.opencode` to `flake.nix`).
2. Complete Phase 2: Foundational (skeleton in `modules/services/opencode.nix` and enable in `modules/hosts/homelab.nix`).
3. Complete Phase 3: User Story 1 (CLI package and declarative config for `homelab`).
4. **VALIDATE MVP**: Run `nix eval .#nixosConfigurations.homelab.config.environment.systemPackages` to confirm OpenCode CLI availability.

### Incremental Delivery

1. Foundation ready → Deliver User Story 1 (Interactive Shell on `homelab`, MVP).
2. Deliver User Story 2 → Mutualize configuration across `desktop-pc` and `macbook-air-m4-15`.
3. Deliver User Story 3 → Launch `opencode serve` daemon and Caddy reverse proxy on `opencode.homelab.vaylet.fr`.
4. Deliver User Story 4 → Configure persistent storage for state and session survival.
5. Finalize with living documentation (`README.md` with dual Bash/Fish code blocks) and run `just check`.
