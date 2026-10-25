---

description: "Task list for enabling Tailscale SSH for dynamic tailnet access without static key distribution"
---

# Tasks: Dynamic Tailnet SSH Access Without Static Key Distribution

**Input**: Design documents from `/specs/022-enable-tailscale-ssh/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/tailscale-ssh-contract.md, quickstart.md

**Tests**: Standalone test suites are not requested; verification is performed via hermetic Nix evaluation (`nix eval`), static analysis (`just lint`), formatting checks (`just fmt`), and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch isolation and environment readiness.

*(No setup tasks required — repository flake inputs and dendritic module structure in `flake.nix` and `modules/services/tailscale.nix` are already initialized on branch `022-enable-tailscale-ssh`.)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure prerequisites.

*(No blocking foundational tasks required — `services.tailscale` is already imported by `modules/hosts/homelab.nix` and `modules/hosts/desktop-pc.nix`.)*

---

## Phase 3: User Story 1 - Keyless Identity-Based Remote Access Across the Private Mesh Network (Priority: P1) 🎯 MVP

**Goal**: Declaratively enable Tailscale SSH (`extraSetFlags = ["--ssh"]`) in `modules/services/tailscale.nix` so that `tailscaled-set.service` runs `tailscale set '--ssh'` automatically on managed NixOS hosts (`homelab` and `desktop-pc`).

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.services.tailscale.extraSetFlags` and `nixosConfigurations.homelab.config.systemd.services.tailscaled-set.script` via `nix eval` to confirm `["--ssh"]` and `tailscale set '--ssh'` are generated.

### Implementation for User Story 1

- [X] T001 [US1] Configure `services.tailscale.extraSetFlags = ["--ssh"];` alongside `enable = true;`, `permitCertUid = "caddy";`, and `systemd.services.tailscaled-set` (`wantedBy = ["multi-user.target"]`, `partOf = ["tailscaled.service"]`, `serviceConfig.RemainAfterExit = true`) in `modules/services/tailscale.nix` per `specs/022-enable-tailscale-ssh/contracts/tailscale-ssh-contract.md`
- [X] T002 [US1] Verify `services.tailscale.extraSetFlags` (`["--ssh"]`) and `systemd.services.tailscaled-set` (`Type = "oneshot"`, `RemainAfterExit = true`, `wantedBy` including `"multi-user.target"`, `script` invoking `tailscale set --ssh`) across `homelab` and `desktop-pc` via `nix eval` against `modules/services/tailscale.nix`

**Checkpoint**: User Story 1 complete — Tailscale SSH is declaratively enabled and `tailscaled-set.service` is synthesized on all NixOS Tailscale hosts.

---

## Phase 4: User Story 2 - Non-Breaking Physical Local Network Fallback Access (Priority: P1)

**Goal**: Ensure traditional key-authenticated OpenSSH (`services.openssh`) and static `authorizedKeys` for `laurent` and `root` remain active on physical LAN interfaces (`192.168.1.180`) without conflict.

**Independent Test**: Evaluate `services.openssh.enable`, `services.openssh.settings.PermitRootLogin`, and `users.users.{laurent,root}.openssh.authorizedKeys.keys` on `homelab` via `nix eval` to confirm physical LAN fallback remains intact.

### Implementation for User Story 2

- [X] T003 [P] [US2] Verify physical LAN OpenSSH fallback coexistence (`services.openssh.enable == true` in `modules/services/ssh.nix`, `users.users.laurent.openssh.authorizedKeys.keys` in `modules/core/base.nix`, and `users.users.root.openssh.authorizedKeys.keys` in `modules/hosts/homelab.nix`) via `nix eval`

**Checkpoint**: User Story 2 complete — physical LAN OpenSSH fallback is verified alongside Tailscale SSH.

---

## Phase 5: User Story 3 - Centralized Access Policy & Living Documentation (Priority: P2)

**Goal**: Document Tailscale SSH usage, the required Tailscale Admin Console `ssh` ACL policy for `laurent` and `root`, LAN fallback coexistence, and dual Bash/Fish command variants in `README.md`.

**Independent Test**: Inspect `README.md` to confirm the Tailscale SSH section documents keyless tailnet SSH access, the JSONC `ssh` ACL policy rule, LAN fallback coexistence, and dual Bash/Fish command blocks where syntax differs.

### Implementation for User Story 3

- [X] T004 [P] [US3] Update `README.md` to document Tailscale SSH dynamic access (`ssh laurent@homelab` / `tailscale ssh laurent@homelab`), the Tailscale Admin Console `ssh` ACL policy stanza (`action: "check"`, `src: ["autogroup:member"]`, `dst: ["homelab"]`, `users: ["laurent", "root"]`), physical LAN OpenSSH fallback coexistence, and dual Bash/Fish command parity per Constitution Principle VI

**Checkpoint**: User Story 3 complete — living documentation in `README.md` is synchronized with dual-shell parity.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute all repository quality gates, formatters, static linters, and full flake checks.

- [X] T005 [P] Format Nix files (`just fmt`) and run static analysis (`just lint`) across `modules/services/tailscale.nix` and `README.md`
- [X] T006 Run full hermetic sandbox check (`just check`) and validate all steps in `specs/022-enable-tailscale-ssh/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 3)**: No prerequisites — can start immediately (`T001` → `T002`).
- **User Story 2 (Phase 4)**: Can run in parallel with or immediately after User Story 1 (`T003`).
- **User Story 3 (Phase 5)**: Can run in parallel with User Story 1 & 2 (`T004` modifies `README.md`, independent of `modules/services/tailscale.nix`).
- **Polish (Phase 6)**: Depends on completion of Phases 3, 4, and 5 (`T005` → `T006`).

### Parallel Opportunities

- `T001` (`modules/services/tailscale.nix`) and `T004` (`README.md`) touch separate files and can be executed in parallel.
- `T002` (Tailscale SSH evaluation) and `T003` (OpenSSH fallback evaluation) are read-only `nix eval` checks that can run in parallel once `T001` completes.

---

## Parallel Example: User Stories 1 & 3

```bash
# Execute implementation edits in parallel across separate files:
Task T001: "Update modules/services/tailscale.nix with extraSetFlags = [\"--ssh\"]"
Task T004: "Update README.md with Tailscale SSH documentation and ACL policy"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 3: User Story 1 (`T001`, `T002`).
2. **STOP and VALIDATE**: Confirm `nix eval .#nixosConfigurations.homelab.config.systemd.services.tailscaled-set.script --raw` outputs the `tailscale set '--ssh'` invocation.
3. Complete Phase 4: User Story 2 (`T003`) to confirm zero regression on physical LAN OpenSSH.
4. Complete Phase 5: User Story 3 (`T004`) to synchronize `README.md`.
5. Complete Phase 6: Polish (`T005`, `T006`) with `just fmt`, `just lint`, and `just check`.
