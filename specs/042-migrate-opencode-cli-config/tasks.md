# Tasks: Migrate OpenCode CLI Configuration

**Input**: Design documents from `/specs/042-migrate-opencode-cli-config/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/opencode-cli-contract.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline verification and repository workspace preparation

- [X] T001 Verify baseline evaluation warnings and git state on branch `042-migrate-opencode-cli-config` using `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Define the declarative OpenCode 2 CLI configuration derivation in `modules/services/opencode.nix` that all downstream consumers rely on

**⚠️ CRITICAL**: Foundational tasks must complete before user story verification

- [X] T002 Define declarative `opencodeCliConfigFile` derivation in `modules/services/opencode.nix` containing `"$schema" = "https://opencode.ai/v2/cli.json"` and `theme = { name = "nord"; }` per `contracts/opencode-cli-contract.md`

**Checkpoint**: Foundational derivation available in module scope for both Home Manager and systemd-tmpfiles deployment.

---

## Phase 3: User Story 1 - Warning-Free System Evaluation and Deployment (Priority: P1) 🎯 MVP

**Goal**: Migrate Home Manager configuration from `programs.opencode.tui` to `programs.opencode.cli`, completely eliminating evaluation warnings across all target host builds.

**Independent Test**: Evaluate `desktop-pc`, `homelab`, and `macbook-air-m4-15` configurations via `nix eval` and verify zero evaluation warnings are emitted.

### Implementation for User Story 1

- [X] T003 [US1] Replace `programs.opencode.tui = { theme = "nord"; };` with `programs.opencode.cli = { theme = { name = "nord"; }; };` in Home Manager block in `modules/services/opencode.nix`
- [X] T004 [US1] Verify zero OpenCode evaluation warnings emitted for `desktop-pc` using `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` per `quickstart.md` Scenario 2
- [X] T005 [US1] Verify multi-host evaluation parity with zero warnings across `homelab` (`nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`) and `macbook-air-m4-15` (`nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath`)

**Checkpoint**: At this point, User Story 1 (MVP) is fully functional: all hosts evaluate cleanly with zero OpenCode deprecation warnings.

---

## Phase 4: User Story 2 - Preservation of Terminal Visual Styling and Client Behavior (Priority: P2)

**Goal**: Guarantee that the Nord visual theme (`theme = { name = "nord"; }`) and modern client settings are active in interactive terminal sessions across both desktop workstations and headless server targets (`homelab`).

**Independent Test**: Verify that evaluated Home Manager `cli` attribute on `desktop-pc` matches `{"theme":{"name":"nord"}}` and that `homelab` links `~/.config/opencode/cli.json` via `systemd.tmpfiles.rules`.

### Implementation for User Story 2

- [X] T006 [US2] Add declarative symlink `"L+ /home/${vars.userName}/.config/opencode/cli.json - - - - ${opencodeCliConfigFile}"` under `systemd.tmpfiles.rules` conditional on `!(config ? home-manager)` in `modules/services/opencode.nix`
- [X] T007 [US2] Verify evaluated CLI configuration output matches `{"theme":{"name":"nord"}}` via `nix eval --json .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.opencode.cli` per `quickstart.md` Scenario 3

**Checkpoint**: At this point, both User Stories 1 and 2 are satisfied: zero evaluation warnings and complete Nord theme parity across all hosts.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates, formatting, static analysis, and live system activation verification

- [X] T008 [P] Format all modified Nix expressions using `just fmt` (`nix fmt .`) per Constitution Principle III
- [X] T009 [P] Run static analysis and dead code checks using `just lint` (`statix check`, `deadnix`) per Constitution Principle III
- [X] T010 Execute hermetic flake checks and pre-commit sandbox checks using `just check` (`nix flake check`)
- [X] T011 Run live non-switching activation test using `just test configuration="desktop-pc"` per `quickstart.md` Scenario 4 and Constitution Principle V

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS user story implementation.
- **User Story 1 (Phase 3)**: Depends on Foundational completion. Delivers MVP (zero evaluation warnings).
- **User Story 2 (Phase 4)**: Depends on Foundational completion. Delivers server host symlink parity.
- **Polish (Phase 5)**: Depends on completion of User Stories 1 and 2.

### User Story Completion Order

```text
Phase 1: Setup (T001)
   │
   ▼
Phase 2: Foundational (T002)
   │
   ├──────────────────────────────┐
   ▼                              ▼
Phase 3: User Story 1 (T003-T005) Phase 4: User Story 2 (T006-T007)
   │                              │
   └──────────────┬───────────────┘
                  ▼
Phase 5: Polish & Quality Gates (T008-T011)
```

### Parallel Opportunities

- Within Phase 5 (Polish): T008 (`just fmt`) and T009 (`just lint`) can be executed independently.
- User Story 1 (T004, T005) evaluation checks can run independently once T003 is implemented.

---

## Parallel Example: Polish Phase

```bash
# Launch formatting and static analysis checks:
just fmt
just lint
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify baseline warning reproduction).
2. Complete Phase 2: Foundational (define `opencodeCliConfigFile`).
3. Complete Phase 3: User Story 1 (replace `tui` with `cli`).
4. **STOP and VALIDATE**: Confirm that `nix eval` runs with zero warnings on `desktop-pc`.

### Incremental Delivery

1. Setup + Foundational → Core derivation ready in `modules/services/opencode.nix`.
2. User Story 1 → Warning eliminated on `desktop-pc` and multi-host evaluations (MVP).
3. User Story 2 → Declarative `cli.json` deployed to `homelab` via tmpfiles.
4. Polish → `just fmt`, `just lint`, `just check`, and `just test` pass with 100% success rate.
