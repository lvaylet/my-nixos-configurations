---

description: "Task list for replacing sgdf-utils with sgdf-tools API on homelab"
---

# Tasks: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Input**: Design documents from `/specs/039-replace-sgdf-tools-api/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Not explicitly requested as TDD unit tests; verification is performed via Nix flake evaluation and quality gate checks (`just fmt`, `just lint`, `just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify current branch isolation and existing service port allocations before modifying flake inputs.

- [X] T001 [P] Verify dedicated feature branch `039-replace-sgdf-tools-api` is active and inspect existing `sgdf-utils` declaration in `flake.nix` and `modules/services/sgdf-utils.nix`
- [X] T002 [P] Verify loopback port `8000` non-collision across existing service modules in `modules/services/` ("Avoids `3000` (`adguardhome`), `3001` (`waha`), `3002` (`uptime-kuma`), etc.")

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Replace the upstream flake input in `flake.nix` and update `flake.lock` so `inputs.sgdf-tools` is available to all NixOS modules.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Replace `inputs.sgdf-utils` with `inputs.sgdf-tools` (`url = "github:lvaylet/sgdf-tools"`, "Must track main branch of `lvaylet/sgdf-tools` in `flake.lock`", and `inputs.nixpkgs.follows = "nixpkgs"`, "Mandatory per Constitution Principle I") in `flake.nix`
- [X] T004 Update `flake.lock` to lock `sgdf-tools` and remove `sgdf-utils` via `nix flake lock --update-input sgdf-tools` in `flake.lock`

**Checkpoint**: `inputs.sgdf-tools` is locked in `flake.lock` and ready for module consumption.

---

## Phase 3: User Story 1 - Seamless Endpoint Continuity for Scripts and n8n Workflows (Priority: P1) 🎯 MVP

**Goal**: Replace `sgdf-utils` with `sgdf-tools` (`services.sgdf-api` and `sgdf-cli`) on `homelab` and expose it through Caddy at `https://sgdf.homelab.vaylet.fr` (`127.0.0.1:8000`).

**Independent Test**: Evaluate `nixosConfigurations.homelab` to confirm `services.sgdf-api.enable` is `true`, `services.sgdf-api.port` is `8000`, `services.caddy.virtualHosts."sgdf.homelab.vaylet.fr".extraConfig` proxies to `127.0.0.1:8000`, and no references to `sgdf-utils` remain in `modules/`.

### Implementation for User Story 1

- [X] T005 [US1] Create dendritic module `flake.modules.services.sgdf-tools` in `modules/services/sgdf-tools.nix` importing `inputs.sgdf-tools.nixosModules.default` ("Imports upstream `services.sgdf-api` module") and configuring `services.sgdf-api` (`enable = true` "Enables `systemd.services.sgdf-api`", `host = "127.0.0.1"` "Loopback-only binding; never exposed directly on LAN/WAN", `port = 8000` "Avoids `3000` (`adguardhome`), `3001` (`waha`), `3002` (`uptime-kuma`), etc.", `dataDir = "/var/lib/sgdf-tools"` "State directory for `sgdf.db` and `sgdf-tools.env`")
- [X] T006 [US1] Configure `environment.systemPackages` (`[ inputs.sgdf-tools.packages.${pkgs.stdenv.hostPlatform.system}.sgdf-cli ]`, "Installs `sgdf` and `sgdf-cli` binaries on the host") and `environment.variables.SGDF_API_URL = "http://127.0.0.1:8000"` ("Default local endpoint for `sgdf-cli` on `homelab`") in `modules/services/sgdf-tools.nix`
- [X] T007 [US1] Configure Caddy virtual host `"sgdf.${vars.homelabDomain}"` ("Preserves exact external URL for scripts and n8n workflows") with `extraConfig = "reverse_proxy 127.0.0.1:8000"` ("Proxies HTTPS traffic on port `443` to local `sgdf-api` listener") and `networking.firewall.allowedTCPPorts = [ 443 ]` in `modules/services/sgdf-tools.nix`
- [X] T008 [US1] Replace `services.sgdf-utils` with `services.sgdf-tools` in `modules/hosts/homelab.nix` and remove obsolete module `modules/services/sgdf-utils.nix`

**Checkpoint**: User Story 1 is complete — `homelab` evaluates `services.sgdf-api` behind Caddy at `https://sgdf.homelab.vaylet.fr` and installs `sgdf-cli`.

---

## Phase 4: User Story 2 - Persistent Database & Automatic Secret Bootstrapping Across Reboots (Priority: P2)

**Goal**: Preserve `/var/lib/sgdf-tools` (`sgdf.db` and `sgdf-tools.env`) across ephemeral `tmpfs` reboots under `/persistent/var/lib/sgdf-tools` with a static `sgdf-tools:sgdf-tools` user/group and automatic first-boot `SGDF_AUTH_TOKEN` generation.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.systemd.services.sgdf-api.serviceConfig.DynamicUser` (`false`) and `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` (confirming `/var/lib/sgdf-tools` is registered with `0750` and `sgdf-tools:sgdf-tools`).

### Implementation for User Story 2

- [X] T009 [US2] Declare static system user `users.users.sgdf-tools = { isSystemUser = true; group = "sgdf-tools"; }` ("Static user required for `preservation` bind mounts") and `users.groups.sgdf-tools = {}` ("Dedicated static group") in `modules/services/sgdf-tools.nix`
- [X] T010 [US2] Configure `systemd.services.sgdf-api` overrides in `modules/services/sgdf-tools.nix`: `after = [ "local-fs.target" ]` ("Ensures `/persistent/var/lib/sgdf-tools` is mounted before `preStart` and `ExecStart`"), `DynamicUser = lib.mkForce false` ("Prevents `/var/lib/private/sgdf-tools` symlink conflict with `/persistent` bind mount"), `User = "sgdf-tools"` ("Runs as static user `sgdf-tools`"), `Group = "sgdf-tools"` ("Runs as static group `sgdf-tools`"), `StateDirectoryMode = "0750"` ("Restricts `/var/lib/sgdf-tools` access to owner/group"), `EnvironmentFile = "-/var/lib/sgdf-tools/sgdf-tools.env"` ("Leading `-` permits first-boot creation in `preStart`"), and `preStart` ("Generates `SGDF_AUTH_TOKEN=<64-hex>` (`0600`) if missing/empty" / "Bootstraps Bearer authentication token without committing secrets to git")
- [X] T011 [US2] Register `/var/lib/sgdf-tools` (`user = "sgdf-tools"`, `group = "sgdf-tools"`, `mode = "0750"`, "Preserved directory mapped from `/persistent/var/lib/sgdf-tools`") in `preservation.preserveAt."/persistent".directories` in `modules/services/sgdf-tools.nix`

**Checkpoint**: User Stories 1 and 2 are complete and verifiable via `nix eval` against `nixosConfigurations.homelab`.

---

## Phase 5: User Story 3 - Synchronized Living Documentation & Dual-Shell Operational Commands (Priority: P3)

**Goal**: Update `README.md` to reflect `sgdf-tools` (`sgdf-api` and `sgdf-cli`) in the Homelab services table, Caddy reverse proxy table, and post-deployment setup instructions with dual Bash/Fish command blocks and legacy DB cleanup instructions.

**Independent Test**: Inspect `README.md` and run `just fmt-md` / `just check` to confirm zero remaining references to `sgdf-utils` and valid Markdown formatting with dual Bash/Fish variants.

### Implementation for User Story 3

- [X] T012 [US3] Update the Homelab hosted services table and Caddy reverse proxy table in `README.md` to replace `sgdf-utils` with `sgdf-tools` (`sgdf-api`), documenting `/var/lib/sgdf-tools` (`sgdf.db`, `sgdf-tools.env`, `sgdf-tools:sgdf-tools`, `0750`) and `https://sgdf.homelab.vaylet.fr` -> `127.0.0.1:8000`
- [X] T013 [US3] Update post-deployment setup item 8 in `README.md` for `sgdf-tools` (`sgdf-api` and `sgdf` CLI), providing dual **Bash** and **Fish** blocks for retrieving `SGDF_AUTH_TOKEN` from `/var/lib/sgdf-tools/sgdf-tools.env`, cleaning up any obsolete `/persistent/var/lib/sgdf-utils` or incompatible `sgdf.db`, importing intranet exports via `sgdf import`, and configuring n8n Bearer authentication

**Checkpoint**: All user stories (US1, US2, US3) are complete and documented.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run formatting, static analysis, evaluation verification, and full flake checks per `quickstart.md`.

- [X] T014 Run `just fmt` and `just lint` to verify `alejandra`, `markdownlint-cli2`, `statix`, and `deadnix` across `flake.nix`, `modules/services/sgdf-tools.nix`, `modules/hosts/homelab.nix`, and `README.md`
- [X] T015 Execute `quickstart.md` `nix eval` assertions for `nixosConfigurations.homelab` (`services.sgdf-api.enable`, `services.sgdf-api.port`, `systemd.services.sgdf-api.serviceConfig.DynamicUser`, `services.caddy.virtualHosts."sgdf.homelab.vaylet.fr".extraConfig`, and `preservation.preserveAt."/persistent".directories`) and run `just check` (`nix flake check`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories (`inputs.sgdf-tools` must exist in `flake.nix` and `flake.lock`).
- **User Story 1 (Phase 3, P1)**: Depends on Foundational (Phase 2).
- **User Story 2 (Phase 4, P2)**: Extends `modules/services/sgdf-tools.nix` created in User Story 1 with static user/group, `preStart` token generation, and `/persistent` preservation.
- **User Story 3 (Phase 5, P3)**: Can proceed in parallel with Phase 3/4 since it only modifies `README.md`.
- **Polish (Phase 6)**: Depends on Phases 3, 4, and 5 completion.

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (`inputs.sgdf-tools`).
- **User Story 2 (P2)**: Builds on `modules/services/sgdf-tools.nix` from US1.
- **User Story 3 (P3)**: Independent file (`README.md`); can be implemented in parallel with US1/US2 after Phase 2.

### Parallel Opportunities

- `T001` and `T002` in Phase 1 can run in parallel.
- Once Phase 2 (`T003`–`T004`) completes, User Story 3 (`T012`–`T013` in `README.md`) can be executed in parallel with User Story 1/2 (`T005`–`T011` in `modules/`).

---

## Parallel Example: User Story 1 & User Story 3

```bash
# After Phase 2 (flake.nix & flake.lock) is complete, run in parallel:
Task: "T005 [US1] Create dendritic module flake.modules.services.sgdf-tools in modules/services/sgdf-tools.nix"
Task: "T012 [US3] Update the Homelab hosted services table and Caddy reverse proxy table in README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2 on `homelab`)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`–`T004`)
3. Complete Phase 3: User Story 1 (`T005`–`T008`)
4. Complete Phase 4: User Story 2 (`T009`–`T011`)
5. Complete Phase 5: User Story 3 (`T012`–`T013`)
6. Complete Phase 6: Polish & Verification (`T014`–`T015`)
