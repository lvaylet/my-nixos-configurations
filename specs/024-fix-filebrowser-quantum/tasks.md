---

description: "Task list for fixing FileBrowser Quantum config persistence and localhost binding"
---

# Tasks: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Input**: Design documents from `/specs/024-fix-filebrowser-quantum/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/filebrowser-service-contract.md, quickstart.md

**Tests**: Standalone test suites are not requested; verification is performed via hermetic Nix evaluation (`nix eval`), static analysis (`just lint`), formatting checks (`just fmt`), and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dedicated branch isolation per Constitution Principle VII.

- [X] T001 Create and switch to dedicated feature branch `024-fix-filebrowser-quantum` from `main` in repository root `.git`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — `services.filebrowser`, `services.media`, `services.caddy`, and `core.preservation` are already wired in `modules/hosts/homelab.nix`.)*

---

## Phase 3: User Story 1 - Persistent User Accounts and Settings Across Container Updates & Reboots (Priority: P1) 🎯 MVP

**Goal**: Mount `/var/lib/filebrowser:/config` inside the FileBrowser Quantum OCI container in `modules/services/filebrowser.nix` so that its SQLite database, user accounts, and settings persist on the host's preserved `/var/lib/filebrowser` directory across container recreations and `homelab` reboots.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.volumes` and `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` via `nix eval` to confirm `/var/lib/filebrowser:/config` is mounted alongside `/data:/srv` and `/var/lib/filebrowser` remains preserved.

### Implementation for User Story 1

- [X] T002 [US1] Uncomment and enable `"/var/lib/filebrowser:/config"` in `virtualisation.oci-containers.containers.filebrowser.volumes` in `modules/services/filebrowser.nix` enforcing the validation rules from `specs/024-fix-filebrowser-quantum/data-model.md`: `volumes` ("MUST include both `/data:/srv` and `/var/lib/filebrowser:/config`.") while retaining `image` ("Pin to `2-stable` upstream image."), `environment.PUID` ("Matches `filebrowser` user UID in `modules/services/media.nix`."), `environment.PGID` ("Matches `multimedia` group GID in `modules/services/media.nix`."), `environment.UMASK` ("Grants `rw-rw-r--` (`664`) to created assets in `/data`."), `extraOptions` ("Ensures supplementary access to `multimedia` group."), `capabilities.CAP_NET_BIND_SERVICE` ("Required by container to bind internal port `80` (`< 1024`)."), and `/var/lib/filebrowser` preservation
- [X] T003 [US1] Verify `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.volumes` via `nix eval` against `modules/services/filebrowser.nix` to confirm it evaluates to `["/data:/srv","/var/lib/filebrowser:/config"]`

**Checkpoint**: User Story 1 complete — FileBrowser Quantum mounts `/var/lib/filebrowser:/config` from the preserved host directory.

---

## Phase 4: User Story 2 - Loopback-Only Binding and Encrypted Reverse Proxy Access (Priority: P1)

**Goal**: Bind the FileBrowser Quantum container port strictly to `127.0.0.1:8081:80` and remove `8081` from `networking.firewall.allowedTCPPorts` in `modules/services/filebrowser.nix` so that all external access goes through the Caddy HTTPS reverse proxy (`https://fb.homelab.vaylet.fr`).

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.ports`, `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts`, and `nixosConfigurations.homelab.config.services.caddy.virtualHosts."fb.homelab.vaylet.fr"` via `nix eval` to confirm `ports` equals `["127.0.0.1:8081:80"]` and `8081` is absent from `allowedTCPPorts`.

### Implementation for User Story 2

- [X] T004 [US2] Update `virtualisation.oci-containers.containers.filebrowser.ports` to `["127.0.0.1:8081:80"]` and replace `8081` with `443` in `networking.firewall.allowedTCPPorts` in `modules/services/filebrowser.nix` enforcing the validation rules from `specs/024-fix-filebrowser-quantum/data-model.md`: `ports` ("MUST bind strictly to `127.0.0.1` so port `8081` is not exposed on `0.0.0.0`."), `networking.firewall.allowedTCPPorts` ("Port `8081` MUST NOT be present in the evaluated `allowedTCPPorts` list on `homelab`."), and `services.caddy.virtualHosts."fb.${vars.homelabDomain}".extraConfig` ("Proxies HTTPS traffic on `fb.<homelabDomain>` to loopback port `8081`.")
- [X] T005 [US2] Verify `nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.ports` (`["127.0.0.1:8081:80"]`) and `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts` (`!(builtins.elem 8081 ports)`) via `nix eval` against `modules/services/filebrowser.nix`

**Checkpoint**: User Story 2 complete — FileBrowser Quantum is strictly bound to `127.0.0.1:8081:80` and port `8081` is closed on the host firewall.

---

## Phase 5: User Story 3 - Synchronized Service Documentation (Priority: P2)

**Goal**: Update `README.md` service and reverse proxy tables to reflect that FileBrowser Quantum is exposed solely via HTTPS (`443` via Caddy), mounts `/var/lib/filebrowser:/config`, and has no direct LAN HTTP endpoint (`N/A (loopback bound)`).

**Independent Test**: Inspect `README.md` lines for FileBrowser Quantum in the `Homelab Hosted Services` and `Reverse Proxy & Secure HTTPS Access` tables to confirm port `8081` is removed from exposed network ports, `/var/lib/filebrowser:/config` is documented, and `LAN Direct URL` is `N/A (loopback bound)`.

### Implementation for User Story 3

- [X] T006 [P] [US3] Update `README.md` (`Homelab Hosted Services` table and `Reverse Proxy & Secure HTTPS Access` table) to list `443` (HTTPS via Caddy) without `8081` (LAN HTTP), `/data:/srv`, `/var/lib/filebrowser:/config` under `Storage / Data`, and `N/A (loopback bound)` under `LAN Direct URL` per `specs/024-fix-filebrowser-quantum/contracts/filebrowser-service-contract.md`

**Checkpoint**: User Story 3 complete — `README.md` accurately reflects the FileBrowser Quantum security and storage configuration.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute all repository quality gates, formatters, static linters, and full flake checks.

- [X] T007 [P] Format Nix files (`just fmt`) and run static analysis (`just lint`) across `modules/services/filebrowser.nix` and `README.md`
- [X] T008 Run full hermetic sandbox check (`just check`) and validate all evaluation commands in `specs/024-fix-filebrowser-quantum/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Must complete first (`T001`) so all work is isolated on branch `024-fix-filebrowser-quantum`.
- **User Story 1 (Phase 3)**: Starts after `T001` (`T002` → `T003`).
- **User Story 2 (Phase 4)**: `T004` edits `modules/services/filebrowser.nix` after `T002` (same file), followed by `T005`.
- **User Story 3 (Phase 5)**: `T006` (`README.md`) touches a separate file and can run in parallel with `T002`/`T004`.
- **Polish (Phase 6)**: Depends on completion of Phases 3, 4, and 5 (`T007` → `T008`).

### User Story Dependencies

- **User Story 1 (P1)**: Independent MVP — mounts `/var/lib/filebrowser:/config` in `modules/services/filebrowser.nix`.
- **User Story 2 (P1)**: Independently testable network security hardening in `modules/services/filebrowser.nix`.
- **User Story 3 (P2)**: Independently verifiable documentation synchronization in `README.md`.

### Parallel Opportunities

- `T006` (`README.md`) can be executed in parallel with `T002`/`T004` (`modules/services/filebrowser.nix`).
- `T003` and `T005` are read-only `nix eval` verification tasks that can run in parallel once `T002` and `T004` complete.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# 1. Execute code and documentation edits in parallel across separate files:
Task T002/T004: "Update modules/services/filebrowser.nix with /var/lib/filebrowser:/config volume, 127.0.0.1:8081:80 port binding, and firewall hardening"
Task T006: "Update README.md service and reverse proxy tables for FileBrowser Quantum"

# 2. Run read-only nix eval verifications in parallel:
Task T003: "Verify homelab filebrowser container volumes via nix eval"
Task T005: "Verify homelab filebrowser container ports and firewall allowedTCPPorts via nix eval"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1: Setup (`T001`).
2. Complete Phase 3: User Story 1 (`T002`, `T003`) to restore persistent `/var/lib/filebrowser:/config` volume mounting.
3. Complete Phase 4: User Story 2 (`T004`, `T005`) to enforce `127.0.0.1:8081:80` loopback binding and close port `8081` on the firewall.
4. Complete Phase 5: User Story 3 (`T006`) to synchronize `README.md`.
5. Complete Phase 6: Polish (`T007`, `T008`) with `just fmt`, `just lint`, and `just check`.
