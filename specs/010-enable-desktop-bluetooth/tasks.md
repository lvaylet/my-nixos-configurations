---
description: "Task list for enabling Bluetooth connectivity on desktop-pc"
---

# Tasks: Enable Bluetooth Connectivity on Desktop-PC

**Input**: Design documents from `/specs/010-enable-desktop-bluetooth/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline inspection of current system evaluation state and hardware configuration

- [X] T001 Inspect baseline Bluetooth evaluation state across desktop-pc and homelab configurations in modules/hosts/desktop-pc.nix

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create dendritic module skeleton and wire host composition

**⚠️ CRITICAL**: Blocking prerequisite for all subsequent user story implementations

- [X] T002 Create the dendritic Bluetooth service module skeleton in modules/services/bluetooth.nix
- [X] T003 Compose services.bluetooth into features list in modules/hosts/desktop-pc.nix

**Checkpoint**: Foundation ready - module is discoverable via `import-tree ./modules` and ready for feature implementation

---

## Phase 3: User Story 1 - Bluetooth Device Discovery and Pairing (Priority: P1) 🎯 MVP

**Goal**: Enable core BlueZ daemon and boot-time adapter power on `desktop-pc` so wireless peripherals can be discovered and paired

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.enable` and `nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.powerOnBoot` returning `true`

### Implementation for User Story 1

- [X] T004 [US1] Configure core Bluetooth daemon and power-on-boot settings in modules/services/bluetooth.nix
- [X] T005 [US1] Validate core Bluetooth option evaluation and system derivation on desktop-pc in modules/hosts/desktop-pc.nix

**Checkpoint**: User Story 1 is functional: `desktop-pc` initializes the Bluetooth controller on boot and enables device discovery

---

## Phase 4: User Story 2 - Audio Routing and Media Stream Playback (Priority: P1)

**Goal**: Ensure wireless audio endpoints (headphones/headsets) are recognized and integrated with PipeWire/WirePlumber

**Independent Test**: Verify that `services.pipewire.enable` and `services.pipewire.pulse.enable` are active in `modules/desktop/audio.nix` with `services.pulseaudio.enable = false`, and system derivation compiles without audio conflicts

### Implementation for User Story 2

- [X] T006 [US2] Verify PipeWire and WirePlumber compatibility with BlueZ audio endpoints in modules/desktop/audio.nix
- [X] T007 [US2] Validate combined Bluetooth and PipeWire system derivation evaluation on desktop-pc in modules/hosts/desktop-pc.nix

**Checkpoint**: User Story 2 is functional: Bluetooth audio endpoints integrate cleanly with PipeWire for seamless playback and recording

---

## Phase 5: User Story 3 - Automatic Reconnection and Persistence Across Reboots (Priority: P2)

**Goal**: Configure BlueZ policies for battery reporting and auto-enablement, and verify persistent pairing storage across reboots

**Independent Test**: Evaluate `hardware.bluetooth.settings.General.Experimental == true` and `hardware.bluetooth.settings.Policy.AutoEnable == true`, and verify `/var/lib/bluetooth` persistence in `modules/core/preservation.nix`

### Implementation for User Story 3

- [X] T008 [US3] Configure BlueZ experimental battery reporting and controller auto-enable policies in modules/services/bluetooth.nix
- [X] T009 [US3] Verify /var/lib/bluetooth directory persistence for paired device keys in modules/core/preservation.nix
- [X] T010 [US3] Validate BlueZ policy settings evaluation on desktop-pc in modules/hosts/desktop-pc.nix

**Checkpoint**: User Story 3 is functional: controller auto-enables, battery status is exposed, and pairing keys survive reboots

---

## Phase 6: User Story 4 - Desktop and Command-Line Device Management (Priority: P2)

**Goal**: Enable Blueman service for GUI/tray management and polkit authorization alongside BlueZ CLI tools

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.desktop-pc.config.services.blueman.enable` returning `true`

### Implementation for User Story 4

- [X] T011 [US4] Configure Blueman management service and D-Bus mechanism in modules/services/bluetooth.nix
- [X] T012 [US4] Validate Blueman service enablement and polkit rule generation on desktop-pc in modules/hosts/desktop-pc.nix

**Checkpoint**: User Story 4 is functional: graphical and command-line Bluetooth management tools are provisioned with unprivileged user access

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Headless server isolation, code hygiene, pre-commit checks, and quickstart validation

- [X] T013 [P] Verify headless server isolation ensuring Bluetooth remains disabled on homelab in modules/hosts/homelab.nix
- [X] T014 [P] Format all modified Nix modules with alejandra via just fmt
- [X] T015 [P] Run static analysis with statix check and dead code detection with deadnix via just lint
- [X] T016 Execute hermetic pre-commit checks across all targets with just check
- [X] T017 Validate complete quickstart verification scenarios in specs/010-enable-desktop-bluetooth/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
  - **User Story 1 (P1)**: Core daemon enablement in `modules/services/bluetooth.nix` (MVP)
  - **User Story 2 (P1)**: Audio subsystem compatibility and verification (depends on US1)
  - **User Story 3 (P2)**: BlueZ policy configuration and persistence (can follow US1)
  - **User Story 4 (P2)**: Blueman desktop manager enablement (can follow US1)
- **Polish (Phase 7)**: Depends on all user stories being complete

### Parallel Opportunities

- Within Phase 7, server isolation check (T013), formatting (T014), and linting (T015) can execute in parallel.
- User Story 3 (policies and persistence) and User Story 4 (Blueman desktop management) can be developed in parallel once Foundational is complete.

---

## Parallel Example: Polish & Code Quality

```bash
# Run isolation verification, formatting, and linting in parallel:
Task: "Verify headless server isolation ensuring Bluetooth remains disabled on homelab in modules/hosts/homelab.nix"
Task: "Format all modified Nix modules with alejandra via just fmt"
Task: "Run static analysis with statix check and dead code detection with deadnix via just lint"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002, T003)
3. Complete Phase 3: User Story 1 (T004, T005)
4. **STOP and VALIDATE**: Confirm that `hardware.bluetooth.enable` and `powerOnBoot` evaluate to `true` on `desktop-pc`

### Incremental Delivery

1. Setup + Foundational → Module skeleton created and wired into `desktop-pc.nix`
2. User Story 1 → Core Bluetooth daemon enabled and powered at boot (MVP)
3. User Story 2 → Audio routing with PipeWire/WirePlumber validated
4. User Story 3 → Battery reporting policies and state persistence verified
5. User Story 4 → Blueman management tools and polkit rules enabled
6. Polish → Server isolation confirmed, formatting and linting pass, pre-commit checks succeed cleanly
