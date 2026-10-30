# Feature Specification: Core System Product Requirements Document (PRD)

**Feature Branch**: `001-system-prd`

**Created**: 2026-08-12

**Status**: Draft

**Input**: User description: "Reverse-engineer and document the Product Requirements Document (PRD) for this existing repository. Detail the core features, user workflows, system goals, and functional scope as currently implemented. Focus strictly on the "what" and "why" without including technical stack or code implementation details."

## Clarifications

### Session 2026-08-12

- Q: How should sensitive credentials and secret configuration data be managed and decrypted across target machines? → A: Declarative in-repo encryption using SOPS and Age host keys (Option A).
- Q: How should system updates and configuration changes be deployed to remote targets such as the headless home server? → A: Local host execution via SSH session and the standardized local task runner (Option A).
- Q: What networking and remote access model should be supported across managed devices? → A: Local LAN/direct SSH by default with optional mesh network overlay (Tailscale) module for remote interconnectivity (Option A).
- Q: How should persistent application state and media storage on the home server profile be structured across system updates? → A: Standard persistent system directories (/var/lib/<service>) and dedicated storage paths that persist across generation switches (Option A).
- Q: How should proprietary and unfree software packages (e.g., Nvidia drivers, VS Code, Obsidian) be governed across machine profiles? → A: Globally allow unfree software packages across all machine profiles (Option A).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-Target Device Provisioning & Profile Management (Priority: P1)

An operator needs to provision, bootstrap, and maintain multiple distinct machine profiles—including a high-performance interactive desktop workstation, a headless 24/7 home server, and a minimal bootable recovery medium—from a single source of truth without configuration drift.

**Why this priority**: Core foundational capability. Without multi-target profile definitions and automated provisioning, machines cannot be deployed or maintained consistently.

**Independent Test**: Can be fully tested by generating any target profile (desktop, homelab, or recovery media) independently and verifying that all target-specific services, hardware settings, and base capabilities are produced accurately according to its profile definition.

**Acceptance Scenarios**:

1. **Given** a new or wiped target machine, **When** booted into the recovery/installation environment, **Then** the system provides immediate network connectivity and a secure shell accessible via the operator's pre-authorized cryptographic keys.
2. **Given** a primary workstation profile request, **When** the system is generated, **Then** graphical desktop capabilities, hardware acceleration, sound subsystems, local developer tools, and user interaction utilities are configured.
3. **Given** a home server profile request, **When** the system is generated, **Then** headless background services, network filtering, media management, file sharing, and container support are enabled while graphical desktop packages are omitted.
4. **Given** global user identity settings (name, email, SSH authorization keys), **When** applied to any managed profile, **Then** user accounts and access credentials are created identically across all machines.

---

### User Story 2 - Safe Verification & Deployment of Configuration Changes (Priority: P1)

A system operator needs to modify system settings or user environment definitions, verify changes against automated quality and security checks, test activations non-destructively in temporary running state, and safely promote them to permanent system generations with immediate rollback capability.

**Why this priority**: Eliminates system downtime, prevents broken boot environments, and protects the operator against configuration errors and secret leaks.

**Independent Test**: Can be fully tested by introducing a configuration update, executing the verification suite to ensure all security/quality rules pass, testing activation in a live session without updating boot defaults, and subsequently switching generations to verify generation rollback availability.

**Acceptance Scenarios**:

1. **Given** pending configuration modifications, **When** the verification suite is run, **Then** code formatting, static correctness rules, unused definition checks, and secret exposure scanners evaluate with zero failures.
2. **Given** verified configuration updates, **When** tested in live mode, **Then** new configurations and services activate immediately for validation without changing the default bootloader generation.
3. **Given** a successfully tested configuration, **When** switched permanently, **Then** the new generation becomes the default boot environment, and a historical rollback generation is preserved in the bootloader.
4. **Given** an unbootable or faulty new generation, **When** rebooting the machine, **Then** the operator can select any previous generation from the boot menu to restore full functionality in under 60 seconds.

---

### User Story 3 - Unified Personal Developer Environment & Tooling (Priority: P2)

A developer working across multiple managed machines expects an identical, customized terminal environment, shell prompt, file navigation tools, text editing configurations, and version control preferences without manually syncing dotfiles.

**Why this priority**: Maximizes daily developer productivity and eliminates context switching and environment discrepancies between workstation and server environments.

**Independent Test**: Can be fully tested by logging into any managed target and verifying that terminal prompts, shell aliases, text editing plugins, git configurations, and search utilities function identically.

**Acceptance Scenarios**:

1. **Given** an interactive terminal session on any managed machine, **When** the operator opens a shell, **Then** custom prompt styling, history navigation, intelligent fuzzy searching, and aliases are immediately active.
2. **Given** a code editing session in terminal or graphical editors, **When** opening source files, **Then** syntax highlighting, code navigation, diagnostics, and auto-formatting are available out of the box.
3. **Given** version control workflows, **When** committing, diffing, rebasing, or resolving merge conflicts, **Then** author identity, conflict resolution tools, and custom git settings are pre-configured.

---

### User Story 4 - Home Infrastructure & Media Services (Priority: P3)

A home lab administrator wants their headless home server to reliably host background network infrastructure, network-wide ad-blocking DNS, media streaming catalogs, local web file browsing, home automation controllers, and isolated container applications.

**Why this priority**: Centralizes home entertainment and network utilities onto dedicated, always-on infrastructure with minimal administrative overhead.

**Independent Test**: Can be fully tested by deploying the homelab profile and verifying that media indexing, DNS filtering, web file management, and container runtimes start automatically and respond to authorized local network traffic.

**Acceptance Scenarios**:

1. **Given** an active home server instance, **When** the system starts up, **Then** DNS filtering, media streaming, file management, home automation, and download services initialize automatically in the background.
2. **Given** network traffic directed at managed service endpoints, **When** accessing declared services, **Then** the system firewall permits authorized service traffic while blocking unexposed ports.
3. **Given** containerized application workloads, **When** deployed on the host, **Then** the container runtime executes them rootlessly or in isolation with standard orchestration tools.

---

### User Story 5 - System Housekeeping & Storage Reclamation (Priority: P4)

A system maintainer needs to periodically optimize local storage, purge outdated generations, clean unreferenced package caches, and update upstream dependencies deterministically.

**Why this priority**: Prevents disk exhaustion over long operating periods and ensures system software receives security and functional updates reliably.

**Independent Test**: Can be fully tested by running generation cleanup and dependency update commands and confirming disk space recovery and deterministic dependency lock file updates.

**Acceptance Scenarios**:

1. **Given** accumulated historical system generations on disk, **When** running a cleanup operation with a retention policy, **Then** generations older than the retention threshold and unreferenced cached files are purged.
2. **Given** upstream component updates, **When** performing a dependency upgrade, **Then** all upstream inputs are resolved and locked deterministically for reproducible builds.

---

### Edge Cases

- **Network Disconnection During System Verification**: The system verification and build processes must succeed offline when using previously fetched dependencies.
- **Faulty Hardware or Kernel Incompatibility**: If a newly built kernel or driver fails to boot, the bootloader menu retains previous working generations with no data loss.
- **Accidental Secret Exposure**: If an unencrypted secret or private key is staged for commit, automated pre-commit scanners must block the action and report the offending file.
- **Service Startup Failure in Server Profile**: If a background home service crashes or fails on boot, the service manager must restart the service and isolate the failure without bringing down the host OS.
- **Disk Storage Exhaustion**: When storage capacity reaches critical thresholds, manual or scheduled garbage collection routines can reclaim unreferenced data without disrupting active profile files.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support distinct, reproducible machine profiles for at least a graphical workstation (`desktop-pc`), a headless server (`homelab`), and a portable rescue/installation image (`iso`).
- **FR-002**: System MUST centralize user identity parameters (operator name, primary email, personal SSH public key, and work SSH public key) in a single shared location and apply them across all machine profiles.
- **FR-003**: System MUST configure pre-authorized SSH access using the operator's public keys across all machine profiles, including the rescue/installation environment.
- **FR-004**: System MUST provide a mechanism to test new configuration changes in the live running session without modifying the default bootloader generation.
- **FR-005**: System MUST maintain historical generations in the bootloader menu (retaining up to a configurable generation count) to enable instant rollback upon reboot.
- **FR-006**: System MUST enforce automated quality gates prior to commit, including code formatting, static analysis, dead-code detection, and multi-engine secret scanning.
- **FR-007**: System MUST provide a single unified command runner interface exposing standardized tasks for building, testing, switching, updating, checking, and cleaning systems.
- **FR-008**: System MUST provide a consistent developer experience across interactive hosts, including shell customizations, command prompts, file navigation utilities, text editor configurations, and git preferences.
- **FR-009**: System MUST enforce a declarative host firewall, blocking all incoming ports by default while allowing traffic to explicitly designated services.
- **FR-010**: System MUST support hosting background services on the server profile, including DNS sinkhole filtering, media streaming, web-based file management, home automation, and container workloads.
- **FR-011**: System MUST provide both automated and on-demand storage reclamation to clean up unreferenced store objects and generations past their retention window.
- **FR-012**: System MUST lock all external dependencies deterministically to guarantee byte-for-byte reproducibility across builds and machines.
- **FR-013**: System MUST support declarative in-repository secret encryption using SOPS and Age host keys, decrypting sensitive values only at system activation time.
- **FR-014**: System MUST support direct LAN communication with a default-deny firewall policy while providing an opt-in encrypted mesh overlay (Tailscale) module for secure cross-network administration.
- **FR-015**: System MUST isolate mutable service databases and media files in dedicated persistent filesystem locations (`/var/lib/<service>`, `/data`, `/media`) that persist intact across system generations and profile rebuilds.
- **FR-016**: System MUST support declarative configuration and installation of proprietary and unfree software packages globally across profiles for hardware acceleration and developer productivity tools.

### Key Entities

- **Machine Profile**: A declarative specification of a target machine defining hardware integration, base OS configuration, system services, and user environment allocations (e.g., Desktop Workstation, Homelab Server, Rescue ISO).
- **User Identity & Environment**: A centralized record of the operator's persona (full name, username, email, SSH credentials) and customized user-space tooling (shell, prompt, editors, file managers, git settings).
- **System Generation**: An immutable, versioned snapshot of the operating system and user profile resulting from a build or switch operation, selectable in the bootloader.
- **Service Definition**: A background daemon or workload (e.g., DNS sinkhole, media server, container runtime, SSH) specifying its lifecycle, configuration parameters, and firewall rules.
- **Unified Task Recipe**: A standardized command entrypoint that automates a discrete lifecycle or maintenance operation (e.g., build, test, switch, lint, format, check, clean).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Rescue/installation image boots to a network-connected, SSH-accessible prompt in under 2 minutes on target hardware.
- **SC-002**: 100% of managed target machines share consistent user identity, authorization keys, and shell environments without manual per-machine intervention.
- **SC-003**: 100% of configuration changes can be verified locally and tested non-destructively prior to permanent activation.
- **SC-004**: Zero plaintext secrets or private keys leaked into version control history.
- **SC-005**: System rollback to a previous working generation can be accomplished via boot menu selection in under 60 seconds.
- **SC-006**: All primary lifecycle operations (build, test, switch, boot, format, lint, check, update, clean) are executable via a single standardized command runner with zero manual path or flag wrestling.

## Assumptions

- Target machines are 64-bit x86 architectures supporting UEFI boot protocols.
- Target machines have access to internet connectivity during initial provisioning and dependency updates.
- The operator authenticates remotely using asymmetric SSH key pairs without password transmission.
- Sensitive runtime credentials (such as service passwords or private tokens) are managed via declarative SOPS encryption using Age keys.
- Remote systems (e.g. headless home server) are updated by connecting via SSH and running the standardized local task runner commands directly on the host.
- Hardware configuration files specific to physical devices (e.g. disk partition UUIDs, GPU drivers) are isolated to individual machine profiles.
- Proprietary and unfree packages (e.g., GPU hardware drivers, specialized IDEs) are permitted globally across all target profiles.
