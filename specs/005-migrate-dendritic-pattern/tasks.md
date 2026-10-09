# Tasks: Codebase Migration to the Dendritic Pattern

**Input**: Design documents from `/specs/005-migrate-dendritic-pattern/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Exact file paths included in all task descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, directory structure creation, and dependency registration

- [x] T001 Create project domain directory structure `modules/core/`, `modules/desktop/`, `modules/services/`, and `modules/hosts/hardware/`
- [x] T002 Add `flake-parts` (`github:hercules-ci/flake-parts`) and `import-tree` (`github:denful/import-tree`) inputs to `flake.nix`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core flake-parts machinery, identity context, and host composition helper

**⚠️ CRITICAL**: No user story work can begin until this foundational phase is complete

- [x] T003 [P] Define multi-system target architectures list (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`) in `modules/core/systems.nix`
- [x] T004 [P] Declare centralized identity options (`user`, `fullName`, `email`, `sshPublicKey`) under `options.flake.vars` in `modules/core/vars.nix`
- [x] T005 Implement `mkHost` composition helper in `modules/core/lib.nix` to assemble NixOS closures with embedded Home Manager modules

**Checkpoint**: Foundational layer complete — feature modules, discovery, and host definitions can now proceed

---

## Phase 3: User Story 1 - Feature-Centric Capability Definition (Priority: P1) 🎯 MVP

**Goal**: Organize all system services and user environment settings by functional feature across domain modules under `modules/`

**Independent Test**: Any individual feature module in `modules/` can be evaluated to produce both its `nixos` system configuration and `homeManager` user environment consistently.

### Implementation for User Story 1

- [x] T006 [P] [US1] Create core foundation base system module in `modules/core/base.nix`
- [x] T007 [P] [US1] Create desktop session module (Niri + Noctalia + Greetd) in `modules/desktop/session.nix`
- [x] T008 [P] [US1] Create terminal emulator module (WezTerm) in `modules/desktop/terminal.nix`
- [x] T009 [P] [US1] Create interactive shell and prompt module (Fish + Starship) in `modules/desktop/shell.nix`
- [x] T010 [P] [US1] Create typography and fonts module (FiraCode Nerd Font) in `modules/desktop/fonts.nix`
- [x] T011 [P] [US1] Create code editor suite module (Neovim/nvf, VS Code, Zed) in `modules/desktop/editors.nix`
- [x] T012 [P] [US1] Create audio and sound service module (Pipewire) in `modules/desktop/audio.nix`
- [x] T013 [P] [US1] Create graphical hardware acceleration module (Nvidia) in `modules/desktop/graphics.nix`
- [x] T014 [P] [US1] Create desktop application tools module in `modules/desktop/apps.nix`
- [x] T015 [P] [US1] Create networking and firewall module in `modules/services/network.nix`
- [x] T016 [P] [US1] Create OpenSSH daemon and client authorization module in `modules/services/ssh.nix`
- [x] T017 [P] [US1] Create Tailscale mesh VPN daemon module in `modules/services/tailscale.nix`
- [x] T018 [P] [US1] Create Podman container runtime module in `modules/services/podman.nix`
- [x] T019 [P] [US1] Create media storage layout and permissions module in `modules/services/media.nix`
- [x] T020 [P] [US1] Create Jellyfin media server service module in `modules/services/jellyfin.nix`
- [x] T021 [P] [US1] Create headless QBittorrent service module in `modules/services/qbittorrent.nix`
- [x] T022 [P] [US1] Create Filebrowser web file manager service module in `modules/services/filebrowser.nix`
- [x] T023 [P] [US1] Create AdGuard Home DNS sinkhole module in `modules/services/adguardhome.nix`
- [x] T024 [P] [US1] Create Home Automation services module in `modules/services/home-automation.nix`
- [x] T025 [P] [US1] Create CUPS printing service module in `modules/services/printing.nix`
- [x] T026 [P] [US1] Create periodic SSD trim service module in `modules/services/ssd.nix`
- [x] T027 [P] [US1] Create virtualization and hypervisor module in `modules/services/virtualization.nix`

**Checkpoint**: All domain feature modules are declared and colocated.

---

## Phase 4: User Story 2 - Automated Feature Discovery & Zero-Boilerplate Inclusion (Priority: P1)

**Goal**: Automatically discover and register all module files in `modules/` using `import-tree` without centralized import lists

**Independent Test**: Adding a test feature file anywhere under `modules/` makes it immediately discoverable and accessible via `config.flake.modules` without editing `flake.nix`.

### Implementation for User Story 2

- [x] T028 [US2] Rewire `flake.nix` outputs to invoke `inputs.flake-parts.lib.mkFlake` with `(inputs.import-tree ./modules)`
- [x] T029 [US2] Verify automated discovery by running `nix flake metadata` and checking top-level module resolution

**Checkpoint**: Every file under `modules/` is dynamically crawled and evaluated as a top-level module.

---

## Phase 5: User Story 3 - Declarative Target Assembly by Feature Composition (Priority: P1)

**Goal**: Declare each target machine (`desktop-pc`, `homelab`, `iso`) by composing hardware profiles with an explicit list of enabled features

**Independent Test**: Each target definition in `modules/hosts/` builds its corresponding NixOS closure cleanly (`just build configuration="desktop-pc"`, `just build configuration="homelab"`, `just build-iso`).

### Implementation for User Story 3

- [x] T030 [P] [US3] Migrate workstation hardware configuration to `modules/hosts/hardware/desktop-pc.nix`
- [x] T031 [P] [US3] Migrate homelab server hardware configuration to `modules/hosts/hardware/homelab.nix`
- [x] T032 [US3] Define desktop workstation closure with declarative feature list in `modules/hosts/desktop-pc.nix`
- [x] T033 [US3] Define homelab server closure with declarative feature list in `modules/hosts/homelab.nix`
- [x] T034 [US3] Define minimal installer ISO closure with declarative feature list in `modules/hosts/iso.nix`

**Checkpoint**: All three target closures assemble declaratively through feature lists and build successfully.

---

## Phase 6: User Story 4 - Unified Identity & Context Without Argument Pass-Through (Priority: P2)

**Goal**: Expose repository-wide user identity and public parameters through top-level options, eliminating `specialArgs` plumbing

**Independent Test**: Modifying user identity attributes in `modules/core/vars.nix` automatically updates git author identity, user account names, and SSH authorizations without passing parameters.

### Implementation for User Story 4

- [x] T035 [US4] Configure `config.flake.vars` defaults in `modules/core/vars.nix` matching user identity ("laurent", "Laurent Vaylet", "laurent.vaylet@gmail.com", SSH key)
- [x] T036 [US4] Verify user account creation and Home Manager user binding in `modules/core/lib.nix` resolves `config.flake.vars.user` without `specialArgs` pass-through

**Checkpoint**: Shared identity is universally accessible across all features via `config`.

---

## Phase 7: User Story 5 - Full Functional Parity & Operational Workflow Continuity (Priority: P1)

**Goal**: Maintain 100% operational parity for `justfile` recipes, multi-system checks, formatters, and CI pipelines, then atomically remove legacy files

**Independent Test**: All tasks in `justfile` (`check`, `lint`, `fmt`, `build`, `test`, `boot`) succeed with exit code 0, and legacy directories are completely removed.

### Implementation for User Story 5

- [x] T037 [P] [US5] Implement multi-system git-hooks pre-commit checks in `modules/core/checks.nix`
- [x] T038 [P] [US5] Implement multi-system `formatter` in `modules/core/formatter.nix`
- [x] T039 [P] [US5] Implement multi-system `devShells.default` with just and nh in `modules/core/devshell.nix`
- [x] T040 [US5] Execute atomic removal of legacy directories `machines/`, `modules/nixos/`, `modules/home-manager/`, and `vars.nix`
- [x] T041 [US5] Validate `just fmt`, `just lint`, and `just check` pass with zero errors
- [x] T042 [US5] Validate closure dry-run builds for `desktop-pc`, `homelab`, and `iso` via `just build` and `just build-iso`

**Checkpoint**: Zero legacy baggage remains and all verification quality gates pass cleanly.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, Constitution amendment to ratify the dendritic pattern, and final end-to-end quickstart validation

- [x] T043 [P] Update `README.md` to document the Dendritic architecture and new `modules/` tree layout
- [x] T044 Amend `.specify/memory/constitution.md` to v2.0.0 updating Principle II to ratify the dendritic pattern
- [x] T045 Run full quickstart validation scenarios from `specs/005-migrate-dendritic-pattern/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1: Setup (T001 - T002)
   │
   ▼
Phase 2: Foundational (T003 - T005)
   │
   ├───────────────────────────────┐
   ▼                               ▼
Phase 3: US1 Features (T006 - T027) Phase 4: US2 Discovery (T028 - T029)
   │                               │
   └───────────────┬───────────────┘
                   ▼
Phase 5: US3 Target Assembly (T030 - T034)
   │
   ▼
Phase 6: US4 Unified Identity (T035 - T036)
   │
   ▼
Phase 7: US5 Parity & Removal (T037 - T042)
   │
   ▼
Phase 8: Polish (T043 - T045)
```

### User Story Dependencies

- **US1 (Features)**: Depends on Foundational Phase (T003-T005). Can implement features in parallel.
- **US2 (Discovery)**: Connects `flake.nix` to `import-tree ./modules`. Works in tandem with US1.
- **US3 (Targets)**: Depends on US1 (features available) and US2 (discovery active).
- **US4 (Identity)**: Integrates with US1/US3 to ensure `config.flake.vars` is consumed cleanly.
- **US5 (Parity & Cleanup)**: Depends on US3 and US4. Executes final verification and legacy tree deletion.

### Parallel Opportunities

- **Phase 1**: T001 and T002 can run sequentially or in quick succession.
- **Phase 2**: T003 and T004 can run in parallel.
- **Phase 3 (US1)**: Tasks T006 through T027 all operate on distinct `.nix` feature files and can be executed completely in parallel.
- **Phase 5 (US3)**: T030 and T031 (hardware migrations) can run in parallel.
- **Phase 7 (US5)**: T037, T038, T039 (checks, formatter, devshell) can run in parallel.
- **Phase 8**: T043 and T044 can run in parallel.

---

## Implementation Strategy

### MVP First (Phases 1, 2, 3, 4, 5)
1. Complete Setup (T001-T002) and Foundational (T003-T005).
2. Migrate and wire core and desktop features (T006-T014).
3. Connect `flake.nix` with `import-tree` (T028-T029).
4. Assemble `desktop-pc` target (T030, T032).
5. **STOP and VALIDATE**: Verify `desktop-pc` evaluates and builds independently.

### Incremental Target Delivery
1. Extend to server services (T015-T027).
2. Assemble `homelab` (T031, T033) and `iso` (T034).
3. Wire multi-system tools and checks (T037-T039).
4. Atomically delete legacy folders (T040).
5. Validate all quality gates (T041-T042) and update docs/constitution (T043-T045).
