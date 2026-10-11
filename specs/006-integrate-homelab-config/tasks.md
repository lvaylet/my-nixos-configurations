---
description: "Task list for homelab configuration integration"
---

# Tasks: Homelab Configuration Integration

**Input**: Design documents from `/specs/006-integrate-homelab-config/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`, `[US5]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Flake & Identity Prerequisites)

**Purpose**: Upstream flake dependencies and centralized identity options

- [x] T001 Add `disko` and `preservation` inputs following `nixpkgs` to `flake.nix`
- [x] T002 [P] Update `modules/core/vars.nix` to declare `sshPublicKeysWork` option supporting multiple work keys alongside existing personal keys
- [x] T003 Update `modules/core/lib.nix` (`mkHost`) to import `inputs.disko.nixosModules.disko` and `inputs.preservation.nixosModules.default` for composed hosts

---

## Phase 2: Foundational (Core System Preservation & Identity Authorization)

**Purpose**: Core preservation rules and global SSH authorization that MUST be complete before user stories begin

**⚠️ CRITICAL**: Blocking prerequisite for homelab host assembly and state persistence

- [x] T004 Create `modules/core/preservation.nix` declaring base system and user state preservation rules under `/persistent` (`/etc/nixos`, `/var/lib/nixos` inInitrd, `/var/log`, `/etc/machine-id` inInitrd, SSH host keys with mode `0600`/`0644` and `configureParent = true`, and user home `.ssh`, `.bash_history`)
- [x] T005 [P] Update `modules/core/base.nix` to authorize both `vars.sshPublicKeyPersonal` and `vars.sshPublicKeysWork` for the primary user account

**Checkpoint**: Foundation ready - user story implementation can begin

---

## Phase 3: User Story 1 - Declarative Impermanence & Partitioning for Homelab (Priority: P1) 🎯 MVP

**Goal**: Declaratively partition homelab storage using Disko (ephemeral tmpfs root, swap, ESP, Btrfs subvolumes `/persistent` and `/nix`) and enable preservation

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.fileSystems."/".fsType` (returns `"tmpfs"`) and verify Disko partition schema and `/persistent` mount configuration

### Implementation for User Story 1

- [x] T006 [US1] Create Disko storage partition declaration in `modules/hosts/_hardware/homelab.nix` specifying nodev tmpfs root (`size=25%`, `mode=755`), NVMe disk `/dev/disk/by-id/nvme-PNY_CS2130_500GB_SSD_PNY16200007380108D83`, MBR (1M, EF02), ESP (1G, EF00, vfat, `/boot`, `umask=0077`), swap (4G, `resumeDevice = true`), and Btrfs root with subvolumes `/persistent` and `/nix` (`mountOptions = ["subvol=persistent", "noatime", "compress=zstd", "ssd", "discard=async"]`) preserving all source comments
- [x] T007 [US1] Update `modules/hosts/homelab.nix` to compose `core.preservation` feature module, override bootloader to disable Limine (`boot.loader.limine.enable = lib.mkForce false`) and enable GRUB 2 (`enable = true`, `efiSupport = true`, `efiInstallAsRemovable = true`), and permit root SSH access (`PermitRootLogin = "prohibit-password"`) with personal and work keys

**Checkpoint**: User Story 1 is functional: homelab evaluates with an impermanent tmpfs root, Disko layout, and persistent state

---

## Phase 4: User Story 2 - Tailored Hardware Optimization for Low-Power Intel Architecture (Priority: P1)

**Goal**: Configure Intel N150 optimizations (ZRAM swap, Intel microcode, schedutil governor, Intel UHD graphics packages, and SSD fstrim) on homelab

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.zramSwap.enable` (returns `true`) and `nix eval .#nixosConfigurations.homelab.config.services.fstrim.enable` (returns `true`)

### Implementation for User Story 2

- [x] T008 [US2] Configure Intel N150 hardware tuning in `modules/hosts/_hardware/homelab.nix` including kernel modules (`xhci_pci`, `nvme`, `usb_storage`, `sd_mod`, `kvm-intel`), ZRAM compressed swap (`algorithm = "zstd"`, `memoryPercent = 50`, `sysctl."vm.swappiness" = 100`), Intel microcode updates (`hardware.cpu.intel.updateMicrocode = true`), CPU governor (`powerManagement.cpuFreqGovernor = "schedutil"`), Intel graphics transcoding packages (`pkgs.intel-media-driver`, `pkgs.intel-compute-runtime`), and weekly `services.fstrim` preserving all source comments

**Checkpoint**: User Story 2 is functional: Alder Lake-N memory, CPU, and GPU optimizations are active on homelab

---

## Phase 5: User Story 3 - Coordinated Multimedia Permissions & Shared Storage (Priority: P2)

**Goal**: Define the shared multimedia domain (group 995, users qbittorrent/filebrowser, SetGID `2775`, systemd tmpfiles `z` mop-up rules, and persistent storage under `/persistent`)

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.homelab.config.users.groups.multimedia.gid` (returns `995`) and verify `systemd.tmpfiles.rules` contain `z` rules for `/data`, `/data/downloads`, and `/data/media`

### Implementation for User Story 3

- [x] T009 [US3] Replace `modules/services/media.nix` with the complete multimedia access model defining group `multimedia` (GID `995`), service users `qbittorrent` (UID `991`) and `filebrowser` (UID `992`), SetGID permissions (`2775`), systemd tmpfiles `z` mop-up rules for `/data`, `/data/downloads`, and `/data/media`, supplementary group configuration, and colocated preservation under `/persistent` preserving all source comments

**Checkpoint**: User Story 3 is functional: shared multimedia permissions and storage directories are coordinated across services

---

## Phase 6: User Story 4 - Modular Homelab Service Suite in Dendritic Architecture (Priority: P1)

**Goal**: Integrate all homelab services as dendritic feature modules under `modules/services/` with colocated preservation and 100% comment retention, and compose them in `homelab.nix`

**Independent Test**: Evaluate container image derivations for filebrowser, homeassistant, portainer, and check native services jellyfin, qbittorrent, and nix-ld evaluate to `true` while adguardhome evaluates to `false`

### Implementation for User Story 4

- [x] T010 [P] [US4] Update `modules/services/podman.nix` to configure Podman runtime with `dockerCompat = true`, `defaultNetwork.settings.dns_enabled = true`, auto-pruning, and colocated preservation for `/var/tmp` and `/var/lib/containers` preserving source comments
- [x] T011 [P] [US4] Replace `modules/services/filebrowser.nix` with Filebrowser Quantum OCI container (`ghcr.io/gtsteffaniak/filebrowser:latest`) on port 8081 with `/data:/srv` volume, PUID 992, PGID 995, UMASK 0002, `CAP_NET_BIND_SERVICE`, firewall port 8081, systemd order after `local-fs.target`, and colocated preservation for `/var/lib/filebrowser` and `/var/cache/filebrowser` preserving source comments
- [x] T012 [P] [US4] Replace `modules/services/home-automation.nix` with Home Assistant OCI container (`ghcr.io/home-assistant/home-assistant:2026.5.3`) on host networking with port 8123 in firewall, systemd order after `local-fs.target`, and colocated preservation for `/var/lib/home-assistant` preserving source comments
- [x] T013 [P] [US4] Create `modules/services/portainer.nix` providing Portainer CE OCI container (`docker.io/portainer/portainer-ce:lts`) with Podman socket volume, privileged mode, ports 8000 and 9443, systemd order after `local-fs.target`, and colocated preservation for `/var/lib/portainer` preserving source comments
- [x] T014 [P] [US4] Update `modules/services/jellyfin.nix` to enable native Jellyfin service bound to `multimedia` group with `openFirewall = true` and colocated preservation for `/var/lib/jellyfin` and `/var/cache/jellyfin` preserving source comments
- [x] T015 [P] [US4] Update `modules/services/qbittorrent.nix` to configure native qBittorrent service with user `qbittorrent`, `openFirewall = true`, serverConfig for downloads in `/data/downloads` and temp in `/data/downloads/temp`, supplementary group `multimedia`, `UMask = "0002"`, and colocated preservation for `/var/lib/qBittorrent` preserving source comments
- [x] T016 [P] [US4] Create `modules/services/nix-ld.nix` enabling `programs.nix-ld.enable = true` with all documentation and references from the source repository
- [x] T017 [US4] Assemble the full feature list in `modules/hosts/homelab.nix` (including `services.podman`, `services.media`, `services.filebrowser`, `services.home-automation`, `services.portainer`, `services.jellyfin`, `services.qbittorrent`, `services.nix-ld`, `services.ssd`) while removing legacy `services.adguardhome` and obsolete desktop modules

**Checkpoint**: User Story 4 is functional: complete application suite operates in modular dendritic architecture

---

## Phase 7: User Story 5 - Flake Inputs & Quality Gates Verification (Priority: P1)

**Goal**: Pin dependencies in `flake.lock`, format all Nix expressions with `alejandra`, ensure zero dead code with `deadnix` and `statix`, and verify flake evaluation across all hosts (`homelab`, `desktop-pc`, `iso`)

**Independent Test**: Run `just fmt`, `just lint`, `just check`, and evaluate toplevel derivation paths for `homelab`, `desktop-pc`, and `iso`

### Implementation for User Story 5

- [x] T018 [US5] Update `flake.lock` with `nix flake lock` to pin `disko` and `preservation` inputs
- [x] T019 [US5] Run code formatter on all modified and newly created Nix expressions in `modules/` and `flake.nix` using `just fmt` (`alejandra`)
- [x] T020 [US5] Run static linting and dead code analysis via `just lint` (`statix`, `deadnix`) across all modified files
- [x] T021 [US5] Verify flake evaluation for `homelab`, `desktop-pc`, and `iso` derivations per `specs/006-integrate-homelab-config/quickstart.md`
- [x] T022 [US5] Run pre-commit hermetic sandboxes via `just check` (`nix flake check`) to verify repository-wide integrity

**Checkpoint**: User Story 5 is functional: all quality gates and evaluation checks pass cleanly

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Verifications across multiple modules and edge-case handling

- [x] T023 [P] Verify that 100% of comments from the source repository files have been retained across all target modules
- [x] T024 [P] Verify that no plaintext secrets or credentials are leaked in `modules/`
- [x] T025 Execute end-to-end validation scenarios documented in `specs/006-integrate-homelab-config/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1): Depends on Phase 2 - Establishes Disko & ephemeral root (MVP)
  - User Story 2 (P1): Can run in parallel with or after US1 - Tunes hardware in `_hardware/homelab.nix`
  - User Story 3 (P2): Depends on Phase 2 - Establishes multimedia user/group/storage baseline
  - User Story 4 (P1): Depends on US1 (storage) and US3 (multimedia permissions) for service operations
  - User Story 5 (P1): Depends on US1–US4 completion - Executes quality gates and builds
- **Polish (Phase 8)**: Depends on all user stories being implemented

### Parallel Opportunities

- Within Phase 1: `T002` [P] can run in parallel with `T001`.
- Within Phase 2: `T005` [P] can run in parallel with `T004`.
- Within Phase 6 (US4): Service modules `T010`, `T011`, `T012`, `T013`, `T014`, `T015`, and `T016` can all be implemented in parallel as they touch independent files in `modules/services/`.
- Within Phase 8: Verification tasks `T023` and `T024` can run in parallel.

---

## Parallel Example: User Story 4 Services

```bash
# Implement independent service modules concurrently:
Task: "T010 [P] [US4] Update modules/services/podman.nix"
Task: "T011 [P] [US4] Replace modules/services/filebrowser.nix"
Task: "T012 [P] [US4] Replace modules/services/home-automation.nix"
Task: "T013 [P] [US4] Create modules/services/portainer.nix"
Task: "T014 [P] [US4] Update modules/services/jellyfin.nix"
Task: "T015 [P] [US4] Update modules/services/qbittorrent.nix"
Task: "T016 [P] [US4] Create modules/services/nix-ld.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`flake.nix`, `vars.nix`, `lib.nix`)
2. Complete Phase 2: Foundational (`core/preservation.nix`, `core/base.nix`)
3. Complete Phase 3: User Story 1 (`_hardware/homelab.nix` Disko layout + `homelab.nix` bootloader)
4. **STOP and VALIDATE**: Verify that `homelab` evaluates with tmpfs root and persistent mounts

### Incremental Delivery

1. Setup + Foundational → Flake inputs and core preservation ready
2. User Story 1 → Disko partitioning and ephemeral root active (MVP)
3. User Story 2 → Intel N150 ZRAM, microcode, and QuickSync GPU tuning active
4. User Story 3 → Shared multimedia users, group, and `/data` permissions active
5. User Story 4 → Full suite of containerized and native services integrated
6. User Story 5 → Flake lock pinned, formatting, linting, and sandbox checks passing
7. Polish → 100% comment retention verified, quickstart validation confirmed
