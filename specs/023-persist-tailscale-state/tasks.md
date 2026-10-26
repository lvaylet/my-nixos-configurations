---

description: "Task list for persisting Tailscale node identity and state across impermanent reboots"
---

# Tasks: Persist Tailscale Node Identity and State Across Impermanent Reboots

**Input**: Design documents from `/specs/023-persist-tailscale-state/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/tailscale-preservation-contract.md, quickstart.md

**Tests**: Standalone test suites are not requested; verification is performed via hermetic Nix evaluation (`nix eval`), static analysis (`just lint`), formatting checks (`just fmt`), and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch isolation and environment readiness.

*(No setup tasks required — repository flake inputs (`preservation`, `nixpkgs`) and dendritic module structure in `flake.nix`, `modules/core/lib.nix`, and `modules/services/tailscale.nix` are already initialized on branch `023-persist-tailscale-state`.)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — `core.preservation` and `services.tailscale` are already imported by `modules/hosts/homelab.nix`, and `inputs.preservation.nixosModules.default` is already wired in `modules/core/lib.nix`.)*

---

## Phase 3: User Story 1 - Uninterrupted Mesh Network Reconnection Across Ephemeral Reboots (Priority: P1) 🎯 MVP

**Goal**: Register `/var/lib/tailscale` in `preservation.preserveAt."/persistent".directories` within `modules/services/tailscale.nix` so that `homelab` preserves its node identity, credentials (`tailscaled.state`), and daemon settings (`--ssh`) across ephemeral `tmpfs` reboots.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` via `nix eval` to confirm `/var/lib/tailscale` is registered with `user = "root"`, `group = "root"`, and `mode = "0700"`.

### Implementation for User Story 1

- [X] T001 [US1] Update `modules/services/tailscale.nix` to accept `{config, lib, ...}:` in the `nixos` module and declare `preservation.preserveAt."/persistent".directories = lib.mkIf config.services.tailscale.enable [{ directory = "/var/lib/tailscale"; user = "root"; group = "root"; mode = "0700"; }]` enforcing the validation rules from `specs/023-persist-tailscale-state/data-model.md`: `directory` ("Must match `tailscaled`'s default state directory (`--statedir=/var/lib/tailscale`)."), `user` ("Must be owned by `root` (the user running `tailscaled`)."), `group` ("Must be owned by group `root`."), and `mode` ("Must restrict read/write/execute access exclusively to `root`.")
- [X] T002 [US1] Verify `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` via `nix eval` against `modules/services/tailscale.nix` to confirm the preserved entry for `"/var/lib/tailscale"` evaluates with `"user": "root"`, `"group": "root"`, and `"mode": "0700"`

**Checkpoint**: User Story 1 complete — `/var/lib/tailscale` is declaratively preserved under `/persistent` with `0700` (`root:root`) permissions on `homelab`.

---

## Phase 4: User Story 2 - Continuous Dependent Service Availability After Reboot (Priority: P1)

**Goal**: Ensure existing Tailscale capabilities required by dependent services—Caddy LocalAPI TLS certificate authorization (`permitCertUid = "caddy"`) and Tailscale SSH (`extraSetFlags = ["--ssh"]` via `systemd.services.tailscaled-set`)—remain intact alongside state preservation.

**Independent Test**: Evaluate `services.tailscale.permitCertUid`, `services.tailscale.extraSetFlags`, `systemd.services.tailscaled-set`, and `systemd.services.caddy.after` on `homelab` via `nix eval` to confirm zero regression on dependent services.

### Implementation for User Story 2

- [X] T003 [P] [US2] Verify dependent service integration on `homelab` (`services.tailscale.permitCertUid == "caddy"`, `services.tailscale.extraSetFlags == ["--ssh"]`, `systemd.services.tailscaled-set.wantedBy` in `modules/services/tailscale.nix`, and `systemd.services.caddy.after` including `"tailscaled.service"` in `modules/services/caddy.nix`) via `nix eval`

**Checkpoint**: User Story 2 complete — dependent Tailscale SSH and Caddy LocalAPI integrations are verified without regression.

---

## Phase 5: User Story 3 - Non-Intrusive Multi-Host Coexistence & Living Documentation (Priority: P2)

**Goal**: Confirm that `desktop-pc` (where `preservation.enable` is `false`) evaluates `modules/services/tailscale.nix` cleanly without activating impermanence, and synchronize `README.md` with `/var/lib/tailscale` persistence documentation and dual Bash/Fish command parity.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config.preservation.enable` (`false`) and `nixosConfigurations.desktop-pc.config.services.tailscale.enable` (`true`) via `nix eval`, and inspect `README.md` to confirm `/var/lib/tailscale` persistence under `/persistent/var/lib/tailscale` is documented with dual Bash/Fish parity.

### Implementation for User Story 3

- [X] T004 [P] [US3] Verify multi-host coexistence on `desktop-pc` (`config.preservation.enable == false` and `config.services.tailscale.enable == true`) via `nix eval` against `modules/hosts/desktop-pc.nix` and `modules/services/tailscale.nix`
- [X] T005 [P] [US3] Update `README.md` (`Homelab Hosted Services` table and `Tailscale SSH Access Control Policy` section) to document `/var/lib/tailscale` state preservation under `/persistent/var/lib/tailscale` (`root:root`, `0700`) across ephemeral `tmpfs` reboots with explicit Bash and Fish command variants per `specs/023-persist-tailscale-state/contracts/tailscale-preservation-contract.md`

**Checkpoint**: User Story 3 complete — multi-host compatibility is verified and `README.md` is synchronized.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute all repository quality gates, formatters, static linters, and full flake checks.

- [X] T006 [P] Format Nix files (`just fmt`) and run static analysis (`just lint`) across `modules/services/tailscale.nix` and `README.md`
- [X] T007 Run full hermetic sandbox check (`just check`) and validate all evaluation commands in `specs/023-persist-tailscale-state/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 3)**: No prerequisites — can start immediately (`T001` → `T002`).
- **User Story 2 (Phase 4)**: Depends on `T001` (`T003` can run in parallel with `T002` and `T004`).
- **User Story 3 (Phase 5)**: `T005` (`README.md`) has no code dependency and can run in parallel with `T001`; `T004` (`desktop-pc` evaluation) runs after `T001` in parallel with `T002` and `T003`.
- **Polish (Phase 6)**: Depends on completion of Phases 3, 4, and 5 (`T006` → `T007`).

### User Story Dependencies

- **User Story 1 (P1)**: Independent MVP — modifies `modules/services/tailscale.nix`.
- **User Story 2 (P1)**: Verifies coexistence with `modules/services/caddy.nix` and `tailscaled-set.service` after `T001`.
- **User Story 3 (P2)**: Verifies `modules/hosts/desktop-pc.nix` evaluation and updates `README.md`.

### Parallel Opportunities

- `T001` (`modules/services/tailscale.nix`) and `T005` (`README.md`) touch separate files and can be executed in parallel.
- `T002`, `T003`, and `T004` are read-only `nix eval` verification tasks that can run in parallel once `T001` completes.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# 1. Execute implementation edits in parallel across separate files:
Task T001: "Update modules/services/tailscale.nix with preservation.preserveAt.\"/persistent\".directories for /var/lib/tailscale"
Task T005: "Update README.md with /var/lib/tailscale persistence documentation"

# 2. Run read-only nix eval verifications in parallel after T001:
Task T002: "Verify homelab preservation directory entry via nix eval"
Task T003: "Verify permitCertUid and extraSetFlags coexistence on homelab via nix eval"
Task T004: "Verify desktop-pc preservation.enable == false via nix eval"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 3: User Story 1 (`T001`, `T002`).
2. **STOP and VALIDATE**: Confirm `nix eval` shows `/var/lib/tailscale` (`root:root`, `0700`) in `homelab`'s `preservation.preserveAt."/persistent".directories`.
3. Complete Phase 4: User Story 2 (`T003`) to confirm zero regression on Caddy LocalAPI and Tailscale SSH.
4. Complete Phase 5: User Story 3 (`T004`, `T005`) to verify `desktop-pc` compatibility and update `README.md`.
5. Complete Phase 6: Polish (`T006`, `T007`) with `just fmt`, `just lint`, and `just check`.
