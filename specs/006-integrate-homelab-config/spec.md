# Feature Specification: Homelab Configuration Integration

**Feature Branch**: `006-integrate-homelab-config`

**Created**: 2026-10-10

**Status**: Draft

**Input**: User description: "Aide-moi à intégrer la configuration de mon homelab, située dans le répertoire `my-first-impermanent-nixos-setup-with-disko-and-preservation` au-dessus du répertoire actuel. La cible est la machine actuelle appelée `hosts/homelab`. Tu as le droit de remplacer tout ce qui concerne cette machine dans la configuration actuelle. La source de vérité est l'autre répertoire. Conserve tous les commentaires de l'autre répertoire. Par contre, adapte la configuration de l'autre répertoire aux spécificités du répertoire actuel, par exemple avec le Dendritic Pattern."

## Clarifications

### Session 2026-10-10

- Q: Should existing services currently configured on `homelab` but absent from the source repository (specifically `adguardhome`, `mosquitto`, and `zigbee2mqtt`) be completely removed to strictly mirror the source repository, or should they be preserved? → A: Strictly mirror the source repository: remove `adguardhome`, `mosquitto`, and `zigbee2mqtt` from the `homelab` host composition so its capability set strictly reflects the source repository.
- Q: How should the existing service definitions in `modules/services/` (`filebrowser.nix`, `home-automation.nix`, `jellyfin.nix`, `qbittorrent.nix`) be adapted to adopt the containerized and permission-coordinated setups from the source repository? → A: Replace existing modules directly in `modules/services/` with the source repository implementations, ensuring no duplicate modules and maintaining a clean tree.
- Q: Should root access over SSH via authorized public keys be permitted on `homelab` as specified in the source repository, or should root login remain completely disabled as configured in the repository's shared OpenSSH module? → A: Allow root SSH access using authorized keys on `homelab` (`PermitRootLogin = "prohibit-password"`), enabling remote management while prohibiting password-based logins.
- Q: Should the centralized identity configuration in `modules/core/vars.nix` be updated to support a list of work SSH public keys containing both keys defined in the source repository, or should only the single existing work key be retained? → A: Update `modules/core/vars.nix` to include both work SSH keys from the source repository, ensuring full access parity across authorized workstations.
- Q: Should the `nix-ld` module from the source repository be integrated into the dendritic tree under `modules/services/nix-ld.nix` and enabled on `homelab`, or should it be omitted? → A: Add `modules/services/nix-ld.nix` with original commentary and enable it on `homelab`, ensuring full operational parity for unpatched binaries and remote developer tooling.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Declarative Impermanence & Partitioning for Homelab (Priority: P1)

As a homelab administrator, I want the homelab host storage to be declaratively partitioned with an ephemeral root in RAM and persistent storage for stateful data and the package store, coupled with declarative preservation rules, so that the machine boots with a fresh, pristine system state on every restart while preserving essential host credentials, system logs, and user configuration.

**Why this priority**: Foundational infrastructural layer. All system operations, services, credentials, and data persistence depend directly on the storage partitioning and impermanence preservation architecture.

**Independent Test**: Can be tested by evaluating the homelab host specification and confirming that declarative storage layout, ephemeral root mapping, and state preservation lists are fully declared and resolve cleanly without evaluation errors.

**Acceptance Scenarios**:

1. **Given** the homelab host configuration, **When** evaluated, **Then** an ephemeral root filesystem is declared in RAM (`tmpfs`), alongside persistent storage partitions and subvolumes for persistent data and package storage.
2. **Given** the declarative preservation configuration, **When** the system state is mapped, **Then** critical system identities (machine ID, SSH host keys, network configurations, system logs) and primary user home files are preserved under `/persistent`.
3. **Given** a reboot of the homelab system, **When** the ephemeral root is cleared, **Then** all explicitly preserved files and directories remain intact while untracked state is discarded.

---

### User Story 2 - Tailored Hardware Optimization for Low-Power Intel Architecture (Priority: P1)

As a homelab administrator, I want the homelab hardware specification to configure performance, memory, and power optimizations tailored to the Intel N150 mini PC architecture, so that the low-power system maximizes memory capacity via compressed swap, balances CPU responsiveness with energy efficiency, accelerates multimedia transcoding, and maintains SSD drive longevity.

**Why this priority**: The Beelink S13 homelab hardware possesses 16 GB of non-expandable RAM and a 4-core efficiency CPU. Compressed in-RAM swap and GPU hardware acceleration are essential to prevent out-of-memory states and CPU bottlenecks when running multiple background services.

**Independent Test**: Can be tested by inspecting the homelab hardware specification module to verify that compressed memory swap, CPU governor parameters, microcode updates, graphics acceleration libraries, and periodic SSD TRIM maintenance are declared.

**Acceptance Scenarios**:

1. **Given** the homelab hardware profile, **When** evaluated, **Then** compressed swap in RAM (ZRAM) is enabled with aggressive kernel swappiness to expand usable memory without prematurely wearing the SSD.
2. **Given** the CPU and graphics configuration, **When** evaluated, **Then** CPU microcode updates, the balanced power governor, and hardware video transcoding acceleration packages are configured.
3. **Given** the NVMe storage device, **When** evaluated, **Then** periodic background TRIM operations are scheduled.

---

### User Story 3 - Coordinated Multimedia Permissions & Shared Storage (Priority: P2)

As a homelab user, I want shared media and download directories with coordinated group permissions and automated permission correction, so that media management, automated downloading, and media streaming services can read and write shared assets cooperatively without permission conflicts or data lockouts.

**Why this priority**: Eliminates inter-service file access permission issues between downloading clients, file management tools, and streaming media servers across ephemeral reboots.

**Independent Test**: Can be tested by evaluating the multimedia service configuration, verifying that dedicated service accounts and groups share a unified multimedia group ID, inherit directory group ownership via SetGID, and enforce consistent file creation masks.

**Acceptance Scenarios**:

1. **Given** the multimedia capability, **When** evaluated, **Then** a shared multimedia group and associated service accounts are declared with fixed identifiers for persistent ownership consistency.
2. **Given** the shared media directories (`/data/downloads` and `/data/media`), **When** accessed by member services, **Then** files and folders inherit the shared group ownership with read/write access.
3. **Given** post-mount permission handling, **When** filesystem paths become ready, **Then** ownership and mode enforcement rules verify and enforce correct group permissions.

---

### User Story 4 - Modular Homelab Service Suite in Dendritic Architecture (Priority: P1)

As a configuration maintainer, I want all homelab application services (file management, home automation, container management, media streaming, download manager, container runtime) modularized as dendritic feature modules with colocated persistence definitions and preserving all original commentary from the source of truth, so that the homelab host cleanly assembles capabilities according to project conventions.

**Why this priority**: Delivers the primary functional role of the homelab machine while ensuring architectural compliance with the project's Dendritic Pattern, eliminating inline configuration bloat in host entrypoints, and retaining valuable architectural notes.

**Independent Test**: Can be tested by verifying that `modules/hosts/homelab.nix` composes hardware and modular features, that each service module colocates service definitions with its specific persistence rules, and that all original comments from the source configuration are preserved intact.

**Acceptance Scenarios**:

1. **Given** the homelab target declaration in `modules/hosts/homelab.nix`, **When** inspected, **Then** it declares only its hardware specification and a list of enabled feature modules without inlined service definitions.
2. **Given** each application service module in the dendritic layout, **When** inspected, **Then** its service configuration, firewall allowances, and associated persistent directories are colocated within the feature scope.
3. **Given** comments and documentation annotations in the source repository, **When** ported to the dendritic modules, **Then** 100% of the comments are retained in their corresponding modules.

---

### User Story 5 - Flake Inputs & Quality Gates Verification (Priority: P1)

As a repository maintainer, I want the root flake to incorporate necessary external declarative storage and persistence modules following `nixpkgs`, and all integrated configurations to pass formatting, linting, and flake evaluation checks, so that the entire codebase remains hermetic, clean, and reliable.

**Why this priority**: Non-negotiable quality gate mandated by the repository constitution. Guarantees that introducing the homelab configuration does not break existing hosts (`desktop-pc`, `iso`) or violate repository standards.

**Independent Test**: Can be tested by running the repository formatting, static linting, and flake evaluation commands across all hosts, confirming all checks succeed with exit code 0.

**Acceptance Scenarios**:

1. **Given** the root `flake.nix`, **When** evaluated, **Then** external partitioning and preservation dependencies are pinned and follow `nixpkgs`.
2. **Given** all target configurations (`homelab`, `desktop-pc`, `iso`), **When** evaluated, **Then** all host derivation graphs build cleanly without syntax or configuration errors.
3. **Given** all newly created and modified Nix expressions, **When** verified with formatting and static analysis tools, **Then** they pass with zero warnings or errors.

---

### Edge Cases

- **Storage Device Identifier Drift**: The storage device in the source configuration targets a specific hardware disk identifier (`/dev/disk/by-id/nvme-PNY_CS2130_500GB_SSD_PNY16200007380108D83`). If evaluated in environments without this physical drive, device references must remain self-contained within the homelab hardware/disko module without affecting other host targets.
- **Bootloader Conflicts**: The project's shared base module configures a modern UEFI bootloader by default, while the homelab storage layout specifies a hybrid MBR/GPT partitioning scheme requiring GRUB 2 with removable EFI installation. The homelab configuration must ensure the appropriate bootloader is selected without conflict.
- **Permission Timing on Ephemeral Boot**: On an impermanent system, systemd tmpfiles creation rules (`d`) can conflict with preservation mounts if evaluated prematurely. The system must use mop-up rules (`z`) that wait for preservation bind mounts to complete before enforcing ownership and permissions.
- **Container Storage Persistence**: Container image layers and volume data must persist across reboots without exhausting RAM tmpfs allocations, requiring `/var/lib/containers` and `/var/tmp` to reside on persistent storage.
- **Shared vs Host-Specific Services**: Modifying shared service modules to support containerized or persisted homelab workloads must preserve compatibility so that desktop and ISO targets remain unaffected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST declare external declarative disk partitioning (`disko`) and state preservation (`preservation`) dependencies in `flake.nix` with inputs following `nixpkgs`.
- **FR-002**: The homelab host MUST implement declarative disk partitioning specifying an ephemeral root filesystem in RAM (`tmpfs`), persistent storage subvolume (`/persistent`), package store subvolume (`/nix`), dedicated swap, and boot partitions.
- **FR-003**: The homelab host MUST implement declarative state preservation, ensuring critical system configuration, machine identity, cryptographic host keys, system logs, network connection credentials, and primary user home directory files persist across reboots.
- **FR-004**: The homelab hardware specification MUST incorporate optimizations for the Intel N150 processor architecture, including compressed swap in RAM (ZRAM) with high swappiness, Intel microcode updates, balanced power governor, Intel graphics hardware acceleration packages, and scheduled NVMe TRIM.
- **FR-005**: The homelab host MUST configure the GRUB 2 bootloader with removable EFI support matching the hybrid partition layout.
- **FR-006**: The system MUST provide an OCI container runtime (Podman) with automatic image pruning, command compatibility, container name DNS resolution, and persistent storage under `/persistent`.
- **FR-007**: The system MUST provide a containerized file management application (Filebrowser Quantum) with access to the shared `/data` storage volume, web interface port exposed through the firewall, and persistent configuration and cache directories under `/persistent`.
- **FR-008**: The system MUST provide a containerized home automation platform (Home Assistant) operating on host networking with required ports exposed through the firewall and persistent configuration under `/persistent`.
- **FR-009**: The system MUST provide a containerized container management interface (Portainer) linked to the container runtime socket with administrative web ports exposed through the firewall and persistent application data under `/persistent`.
- **FR-010**: The system MUST provide a native media streaming service (Jellyfin) bound to the shared multimedia group with required firewall ports opened and persistent program data and cache under `/persistent`.
- **FR-011**: The system MUST provide a native BitTorrent client (qBittorrent) with download and temporary directories configured under `/data/downloads`, service credentials and permissions aligned with the multimedia group, and persistent application state under `/persistent`.
- **FR-012**: The system MUST configure a shared multimedia permission model, including dedicated user and group identifiers for multimedia services, SetGID inheritance on shared media paths, and post-mount tmpfiles rules to enforce access rights without race conditions.
- **FR-013**: The homelab configuration MUST adhere strictly to the Dendritic Pattern: `modules/hosts/homelab.nix` MUST only compose hardware and feature modules, and individual capability modules under `modules/` MUST encapsulate their respective system services, container definitions, and firewall rules.
- **FR-014**: Each feature module MUST colocate its respective declarative preservation definitions, conditionally applying persistent directory mappings when the feature is active.
- **FR-015**: All explanatory comments, implementation rationale, and technical annotations from the source repository MUST be preserved verbatim in the target modules.
- **FR-016**: The homelab host MUST resolve user identity, full name, email, and authorized SSH keys from the centralized identity options (`config.flake.vars`).
- **FR-017**: All integrated Nix modules MUST format cleanly with `alejandra` and pass static linting and dead code detection with zero errors.
- **FR-018**: The system MUST exclude services not present in the source repository (specifically `adguardhome`, `mosquitto`, and `zigbee2mqtt`) from the `homelab` host composition.
- **FR-019**: Existing service modules in `modules/services/` (`filebrowser.nix`, `home-automation.nix`, `jellyfin.nix`, `qbittorrent.nix`, `media.nix`) MUST be replaced in-place with the source repository implementations, and new services (`portainer.nix`) added as dendritic modules under `modules/services/`.
- **FR-020**: The homelab configuration MUST permit root SSH logins using authorized public keys (`PermitRootLogin = "prohibit-password"`), enabling secure remote management while prohibiting password authentication.
- **FR-021**: The system MUST update `modules/core/vars.nix` and `modules/core/base.nix` to support and authorize all personal and work SSH public keys defined in the source repository.
- **FR-022**: The system MUST provide a dendritic feature module `modules/services/nix-ld.nix` (enabling `programs.nix-ld`) preserving original source commentary, and enable it on the `homelab` host.

### Key Entities

- **Homelab Host Composition (`modules/hosts/homelab.nix`)**: Target machine declaration composing hardware specifications and enabled dendritic feature modules using `mkHost`.
- **Hardware Profile (`modules/hosts/_hardware/homelab.nix`)**: Encapsulates CPU, memory, kernel modules, graphics drivers, and hardware maintenance settings for the Beelink S13 mini PC.
- **Declarative Partitioning Schema**: Disko specification defining disk partitions (MBR, ESP, swap, root Btrfs with subvolumes) and RAM-backed ephemeral root.
- **Preservation Schema**: Declarative mappings defining which system and user paths are linked or bind-mounted from persistent storage into the ephemeral root filesystem.
- **Multimedia Environment**: Permission and storage domain coordinating the `multimedia` group, application service users, and persistent data paths (`/data/downloads`, `/data/media`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Nix flake evaluation of `#nixosConfigurations.homelab` completes successfully with exit code 0 and generates a valid system derivation graph.
- **SC-002**: 100% of functional capabilities present in the source repository (ephemeral root, preservation, hardware tuning, container runtime, filebrowser, home assistant, portainer, jellyfin, qbittorrent, shared multimedia permissions) are fully declared and operational in the target homelab configuration.
- **SC-003**: 100% of explanatory comments and annotations present in the source files are retained within the target dendritic configuration files.
- **SC-004**: All other host targets (`desktop-pc`, `iso`) continue to evaluate successfully with zero regressions introduced by shared module additions or modifications.
- **SC-005**: 100% of newly added or modified Nix expressions pass automated formatting (`alejandra`) and static analysis linting (`statix`, `deadnix`) with zero errors or warnings.
- **SC-006**: Target host definition in `modules/hosts/homelab.nix` contains zero inline service definitions, fulfilling the Dendritic Pattern constraint.

## Assumptions

- Target machine architecture is `x86_64-linux`.
- Target hardware is a Beelink S13 mini PC with an Intel N150 processor (Alder Lake-N) and 16 GB RAM.
- Storage device path `/dev/disk/by-id/nvme-PNY_CS2130_500GB_SSD_PNY16200007380108D83` from the source repository is the canonical disk identifier on the target physical machine.
- User identity parameters in `modules/core/vars.nix` (`laurent`, "Laurent VAYLET", user email, and authorized SSH public keys) serve as the single source of truth for user account setup and SSH access.
- GRUB 2 bootloader with removable EFI support is required for homelab to support the hybrid MBR/GPT partitioning layout, overriding the default Limine bootloader used on desktop systems.
- Services that run in OCI containers (Filebrowser Quantum, Home Assistant, Portainer) run under Podman container engine with systemd supervision.
- Legacy services currently configured in `modules/hosts/homelab.nix` that are not present in the source repository (`adguardhome`, `mosquitto`, `zigbee2mqtt`) are intentionally excluded to maintain strict fidelity to the source of truth.
