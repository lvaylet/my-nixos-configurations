# Tasks: Core System Product Requirements Document (PRD)

**Input**: Design documents from [`specs/001-system-prd/`](.)

**Prerequisites**: [`plan.md`](plan.md) (required), [`spec.md`](spec.md) (required), [`research.md`](research.md), [`data-model.md`](data-model.md), [`contracts/`](contracts/)

**Organization**: Tasks are grouped by user story (P1 through P4) to enable independent implementation and validation.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Repository initialization, dependency pinning, shared identity, and quality tooling.

- [x] T001 Initialize repository structure and flake inputs in `flake.nix` and `flake.lock`
- [x] T002 [P] Define centralized user identity and SSH credentials in `vars.nix`
- [x] T003 [P] Configure pre-commit quality hooks and sandboxed checks in `flake.nix` and `.pre-commit-config.yaml`
- [x] T004 [P] Configure project constitution and governance rules in `.specify/memory/constitution.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core base modules and task runner infrastructure required by all machine profiles and user stories.

**⚠️ CRITICAL**: Must be completed before deploying any machine profiles.

- [x] T005 Implement core base NixOS module with bootloader, locale, user setup, and GC in `modules/nixos/base.nix`
- [x] T006 [P] Implement core base Home Manager module with stateVersion and systemd service switching in `modules/home-manager/base.nix`
- [x] T007 [P] Implement system-wide default packages in `modules/nixos/_packages.nix`
- [x] T008 [P] Implement user-level default package set in `modules/home-manager/_packages.nix`
- [x] T009 Define standardized operational task runner recipes in `justfile`

**Checkpoint**: Foundation ready — machine profiles and user stories can now be implemented and verified.

---

## Phase 3: User Story 1 - Multi-Target Device Provisioning & Profile Management (Priority: P1) 🎯 MVP

**Goal**: Provision, bootstrap, and maintain distinct machine profiles for a workstation (`desktop-pc`), a home server (`homelab`), and a rescue image (`iso`) sharing centralized identity and SSH access.

**Independent Test**: Build and evaluate derivations for `desktop-pc`, `homelab`, and `iso` from `flake.nix` and verify that all hardware configs, base modules, and user mappings generate without errors.

- [x] T010 [P] [US1] Implement primary workstation host composition in `machines/desktop-pc/configuration.nix`
- [x] T011 [P] [US1] Implement workstation hardware configuration in `machines/desktop-pc/hardware-configuration.nix`
- [x] T012 [P] [US1] Implement home server host composition in `machines/homelab/configuration.nix`
- [x] T013 [P] [US1] Implement home server dummy hardware specification in `machines/homelab/hardware-configuration-dummy.nix`
- [x] T014 [P] [US1] Implement minimal rescue & installation ISO profile in `machines/iso/configuration.nix`
- [x] T015 [US1] Configure top-level multi-host system outputs in `flake.nix`

**Checkpoint**: User Story 1 complete — all 3 machine profiles are definable and buildable from `flake.nix`.

---

## Phase 4: User Story 2 - Safe Verification & Deployment of Configuration Changes (Priority: P1)

**Goal**: Execute automated pre-commit quality and secret scans, test activation non-destructively in the running session, switch live profiles, and maintain bootloader rollback entries.

**Independent Test**: Run `just check`, test non-switching activation via `just test configuration="desktop-pc"`, and verify bootloader configuration in `modules/nixos/base.nix`.

- [x] T016 [P] [US2] Configure multi-engine secret detection hooks in `flake.nix`
- [x] T017 [P] [US2] Configure `alejandra` code formatting and devshell integration in `flake.nix`
- [x] T018 [US2] Implement build, test, switch, and boot operational recipes in `justfile`
- [x] T019 [US2] Configure `Limine` bootloader with multi-generation retention and theme customization in `modules/nixos/base.nix`
- [x] T020 [US2] Configure declarative secret management and decryption support via SOPS/Age in `modules/nixos/base.nix`

**Checkpoint**: User Story 2 complete — changes can be verified hermetically, tested in dry-run mode, and rolled back via the bootloader in <60s.

---

## Phase 5: User Story 3 - Unified Personal Developer Environment & Tooling (Priority: P2)

**Goal**: Provide an identical shell, prompt, text editor, fuzzy finder, and git environment across interactive targets.

**Independent Test**: Open terminal session on managed profile and verify prompt (`starship`), shell (`zsh`), git configuration, and editor (`nvf`/`neovim`).

- [x] T021 [P] [US3] Implement interactive Zsh shell environment and aliases in `modules/home-manager/_zsh.nix`
- [x] T022 [P] [US3] Implement Starship prompt configuration in `modules/home-manager/starship.nix`
- [x] T023 [P] [US3] Implement declarative Git author identity and workflow settings in `modules/home-manager/git.nix`
- [x] T024 [P] [US3] Implement declarative Neovim editor configuration via `nvf` in `modules/nixos/neovim.nix`
- [x] T025 [P] [US3] Implement Ghostty terminal emulator configuration in `modules/home-manager/ghostty.nix`
- [x] T026 [P] [US3] Implement VS Code extensions and settings in `modules/home-manager/vscode.nix`
- [x] T027 [P] [US3] Implement Zed editor settings in `modules/home-manager/zed-editor.nix`
- [x] T028 [P] [US3] Implement CLI productivity utilities in `modules/home-manager/bat.nix`, `modules/home-manager/eza.nix`, `modules/home-manager/fzf.nix`, and `modules/home-manager/yazi.nix`

**Checkpoint**: User Story 3 complete — uniform developer productivity environment available on interactive hosts.

---

## Phase 6: User Story 4 - Home Infrastructure & Media Services Management (Priority: P3)

**Goal**: Host background network services (AdGuard Home, Jellyfin, Home Assistant, Filebrowser, QBittorrent, Tailscale, Podman) on server profile with firewall protection.

**Independent Test**: Build and verify homelab profile with background systemd services and firewall open ports.

- [x] T029 [P] [US4] Implement AdGuard Home DNS sinkhole module in `modules/nixos/adguardhome.nix`
- [x] T030 [P] [US4] Implement Jellyfin media server and streaming module in `modules/nixos/jellyfin.nix`
- [x] T031 [P] [US4] Implement Home Assistant automation controller in `modules/nixos/home-automation.nix`
- [x] T032 [P] [US4] Implement Filebrowser web file manager module in `modules/nixos/filebrowser.nix`
- [x] T033 [P] [US4] Implement QBittorrent download service module in `modules/nixos/qbittorrent.nix`
- [x] T034 [P] [US4] Implement Tailscale encrypted mesh network module in `modules/nixos/tailscale.nix`
- [x] T035 [P] [US4] Implement Podman container engine module in `modules/nixos/podman.nix`
- [x] T036 [US4] Configure declarative firewall and network manager rules in `modules/nixos/network.nix`

**Checkpoint**: User Story 4 complete — home infrastructure services fully operational behind declarative firewall.

---

## Phase 7: User Story 5 - System Housekeeping & Storage Reclamation (Priority: P4)

**Goal**: Clean obsolete profile generations, purge unreferenced store objects, and update dependency locks deterministically.

**Independent Test**: Run `just clean`, `just clean-all`, and `just up` to verify garbage collection and lockfile updates.

- [x] T037 [P] [US5] Implement automated periodic garbage collection in `modules/nixos/base.nix`
- [x] T038 [US5] Implement user and system-wide generation cleanup recipes (`clean`, `clean-all`, `collect-garbage`, `delete-old-generations`) in `justfile`
- [x] T039 [US5] Implement upstream dependency update recipe (`up`) in `justfile`

**Checkpoint**: User Story 5 complete — automated storage management and deterministic updates enabled.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, stateVersion synchronization, and validation guide execution.

- [x] T040 [P] Document complete repository usage, recipes, and flake outputs in `README.md`
- [x] T041 [P] Verify consistency of `system.stateVersion` and `home.stateVersion` across all modules in `modules/nixos/base.nix` and `modules/home-manager/base.nix`
- [x] T042 Execute end-to-end quickstart validation scenarios defined in `specs/001-system-prd/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

```mermaid
graph TD
    Phase1[Phase 1: Setup] --> Phase2[Phase 2: Foundational]
    Phase2 --> Phase3[Phase 3: US1 - Multi-Target Profiles (MVP)]
    Phase2 --> Phase4[Phase 4: US2 - Safe Deployment & Gates]
    Phase2 --> Phase5[Phase 5: US3 - Developer Tooling]
    Phase2 --> Phase6[Phase 6: US4 - Home Services]
    Phase2 --> Phase7[Phase 7: US5 - Housekeeping & GC]
    Phase3 --> Phase8[Phase 8: Polish & Validation]
    Phase4 --> Phase8
    Phase5 --> Phase8
    Phase6 --> Phase8
    Phase7 --> Phase8
```

---

## Implementation Strategy

### MVP Scope (Phase 1 + Phase 2 + Phase 3)

1. Complete Setup and Foundational infrastructure (`vars.nix`, `modules/nixos/base.nix`, `modules/home-manager/base.nix`, `justfile`).
2. Deliver User Story 1 (`machines/desktop-pc`, `machines/homelab`, `machines/iso`, and `flake.nix`).
3. Validate independent generation build for all 3 target profiles.

### Incremental Feature Expansion

- **Increment 1 (US2)**: Enable quality gates, secret scanning, and non-switching activation tests.
- **Increment 2 (US3)**: Deploy personal shell, editor (`nvf`), and CLI environment.
- **Increment 3 (US4)**: Enable home server media and network services.
- **Increment 4 (US5)**: Automate garbage collection and dependency updates.
