# Feature Specification: Codebase Migration to the Dendritic Pattern

**Feature Branch**: `feat-migrate-dendritic-pattern`

**Created**: 2026-10-09

**Status**: Draft

**Input**: User description: "Migre cette base de code Nix vers le Dendritic Pattern."

## Clarifications

### Session 2026-10-09

- Q: Which architectural framework should orchestrate the dendritic module evaluation and automatic feature discovery? → A: `flake-parts` paired with `vic/import-tree` (canonical dendritic pattern where every non-entrypoint file is a top-level module automatically discovered and merged).
- Q: How should the repository directory structure be organized to store the dendritic feature modules and machine definitions? → A: Domain-grouped layout under `modules/` (e.g., `modules/core/`, `modules/desktop/`, `modules/services/`, `modules/hosts/`), all discovered automatically via a single `import-tree ./modules` call.
- Q: Should Home Manager user environments remain strictly embedded within the NixOS target configurations, or should they also be exposed as standalone configuration outputs? → A: Embedded within NixOS targets only (`home-manager.nixosModules.home-manager`), preserving the exact operational model without adding standalone `homeConfigurations` outputs.
- Q: Should the migration to the dendritic pattern be executed as a single atomic conversion across all hosts and modules, or in phased milestones? → A: Atomic conversion (all modules, hosts `desktop-pc`, `homelab`, and `iso` migrated in a single cohesive pass, removing legacy directories immediately).
- Q: How should shared identity and repository-wide variables currently stored in `vars.nix` be integrated into the dendritic architecture? → A: Top-level module option under `modules/core/vars.nix` accessible across all modules via `config`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Feature-Centric Capability Definition (Priority: P1)

As a configuration maintainer, I want to define system capabilities and user environments grouped together by feature across domain directories (e.g., `modules/desktop/`, `modules/services/`, `modules/core/`), so that all settings and configurations for a specific capability are colocated in a single logical location rather than fragmented across separate system and user directory hierarchies.

**Why this priority**: Foundational core capability of the Dendritic Pattern. Eliminates the cognitive load and maintenance burden of navigating disconnected directory trees to implement or modify a single logical feature.

**Independent Test**: Can be fully tested by creating or modifying a single feature definition containing both system-level and user-level components, building the target configuration, and verifying that both system services and user environment settings are applied consistently.

**Acceptance Scenarios**:

1. **Given** a feature requiring both system-level services and user-level application settings, **When** the maintainer creates the feature definition in its appropriate domain folder, **Then** both aspects are colocated within the same feature declaration file.
2. **Given** an existing feature definition, **When** the maintainer modifies or extends its parameters, **Then** all associated system and user behaviors update consistently without requiring manual edits to external import lists.
3. **Given** a feature that only defines system services or only defines user-level tools, **When** the maintainer defines it, **Then** it cleanly defines only the relevant aspect without requiring empty placeholder blocks.

---

### User Story 2 - Automated Feature Discovery & Zero-Boilerplate Inclusion (Priority: P1)

As a system author, I want newly created feature files anywhere in the `modules/` tree to be automatically discovered and registered by `import-tree`, so that I never have to manually edit centralized import arrays, index files, or root entrypoints when adding or reorganizing features.

**Why this priority**: Eliminates repetitive glue code, manual registration errors, and configuration drift whenever new capabilities are added, renamed, or refactored.

**Independent Test**: Can be fully tested by adding a new feature file to the `modules/` tree without modifying root entrypoints, and confirming that the configuration engine automatically registers the feature and makes it available to target machines.

**Acceptance Scenarios**:

1. **Given** a new feature file added anywhere within the `modules/` tree, **When** the configuration evaluates, **Then** the feature is automatically discovered and available for inclusion across all targets.
2. **Given** a feature file moved or renamed within `modules/`, **When** evaluating the configuration, **Then** the engine resolves the feature without requiring updates to centralized index files.
3. **Given** an unused feature file present in the repository, **When** evaluating target machines that do not enable that feature, **Then** the unused feature does not inject unwanted services or packages into those targets.

---

### User Story 3 - Declarative Target Assembly by Feature Composition (Priority: P1)

As an infrastructure operator, I want each target machine (`modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`, and `modules/hosts/iso.nix`) to declare its configuration simply by specifying its hardware characteristics and a list of enabled features, so that target declarations remain concise, readable, and focused purely on hardware and role composition.

**Why this priority**: Provides crystal-clear visibility into what capabilities each machine possesses while keeping target entrypoints minimal and free of inline configuration boilerplate.

**Independent Test**: Can be fully tested by inspecting each target machine definition to verify it consists solely of hardware specifics plus an explicit declaration of enabled features, and building each target closure to verify all expected services and packages are present.

**Acceptance Scenarios**:

1. **Given** a desktop workstation target, **When** querying its declaration in `modules/hosts/`, **Then** it specifies its hardware profile and enabled features (such as desktop environment, developer toolchain, audio, and graphics) without inlined service configurations or path-based import chains.
2. **Given** a server target, **When** querying its declaration in `modules/hosts/`, **Then** it enables server-specific features (media services, container engine, remote access) and excludes desktop-specific features.
3. **Given** an installation media target, **When** querying its declaration in `modules/hosts/`, **Then** it composes diagnostic and recovery features into a bootable image specification.
4. **Given** a feature added to a target's feature list, **When** building the target, **Then** all system daemons and user tools specified by that feature are included in the generated closure.

---

### User Story 4 - Unified Identity & Context Without Argument Pass-Through (Priority: P2)

As a system administrator, I want shared identity attributes (primary username, full name, email address, SSH public keys) declared as a top-level module under `modules/core/vars.nix` and universally accessible across all features via `config`, so that identity settings remain single-sourced and maintainable without manual argument pass-through.

**Why this priority**: Eliminates fragile parameter pass-through boilerplate across module boundaries and guarantees consistent user identity resolution across all enabled features.

**Independent Test**: Can be fully tested by updating a shared identity parameter in `modules/core/vars.nix`, rebuilding target environments, and verifying that user accounts, version control author settings, and authorization keys reflect the updated value across all features.

**Acceptance Scenarios**:

1. **Given** shared identity parameters defined in `modules/core/vars.nix`, **When** any feature references the primary user identity or contact information via `config`, **Then** the value is resolved consistently without requiring manual parameter pass-through in module arguments.
2. **Given** a target machine with multiple features enabled, **When** building the user environment, **Then** all user-level features automatically associate with the target's primary user account.

---

### User Story 5 - Full Functional Parity & Operational Workflow Continuity (Priority: P1)

As an operator and developer, I want the refactored codebase to preserve 100% functional parity across all installed software, desktop environments, server services, task runner recipes, and verification checks, so that day-to-day operations and CI pipelines continue without disruption.

**Why this priority**: Non-negotiable quality gate. Architectural reorganization must never compromise system stability, functional behavior, or operational tooling.

**Independent Test**: Can be fully tested by running all automated verification tasks (syntax validation, formatting, linting, dead-code detection, pre-commit sandboxes) and successfully building all defined machine closures.

**Acceptance Scenarios**:

1. **Given** the migrated codebase, **When** running automated quality verification commands, **Then** all syntax validation, flake evaluation, and sandbox checks pass with exit code 0.
2. **Given** the migrated codebase, **When** building system closures for all targets, **Then** each target build succeeds and produces closures functionally identical to pre-migration baselines.
3. **Given** operational commands for building, testing, switching, and creating installation media, **When** invoked, **Then** they execute with the same arguments and produce identical operational outcomes.

---

### Edge Cases

- **Hardware-Specific Features**: Features requiring specific physical hardware (e.g., discrete GPU acceleration or touchpad management) must cleanly activate only on targets possessing matching hardware without causing evaluation errors on headless or virtual targets.
- **Tools Without System Daemons**: Features providing standalone user CLI utilities without system daemons (e.g., text filters, pager tools, terminal file managers) must integrate seamlessly alongside complex features providing both daemons and client interfaces.
- **Target Independence & Isolation**: Enabling or disabling a feature on one target machine must have zero effect on the configuration closures or builds of other targets.
- **Non-NixOS Environment Compatibility**: Multi-platform development shells and portable environments must remain fully functional on non-NixOS platforms (such as macOS, WSL2, or standard Linux distributions) without evaluating NixOS-specific modules.
- **Offline / Hermetic Evaluation**: Automated discovery of feature files must operate strictly on local filesystem paths without requiring internet connectivity or dynamic external lookups during evaluation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST organize configuration capabilities into domain-grouped features under a unified `modules/` tree (e.g., `modules/core/`, `modules/desktop/`, `modules/services/`, `modules/hosts/`).
- **FR-002**: Feature definitions MUST support specifying both system-level configurations and user-level environment settings within a unified feature scope.
- **FR-003**: The configuration engine MUST use `flake-parts` combined with `import-tree` to automatically discover and evaluate all feature definitions in the `modules/` tree without requiring manual import statements in centralized index files.
- **FR-004**: Adding, renaming, or moving a feature file within the `modules/` tree MUST NOT require modifying root entrypoints or registration files.
- **FR-005**: Each target machine (`desktop-pc`, `homelab`, `iso`) MUST be declared in `modules/hosts/` by composing its hardware profile with an explicit list of selected features.
- **FR-006**: Target declarations MUST NOT require boilerplate service definitions or manual module import paths.
- **FR-007**: Shared identity variables (username, full name, email, SSH public keys) MUST be declared as top-level configuration options under `modules/core/vars.nix` and universally accessible across all features via `config` without manual argument pass-through.
- **FR-008**: User-level configurations within enabled features MUST be integrated directly into target NixOS closures via embedded Home Manager module integration (`home-manager.nixosModules.home-manager`) bound to the configured primary user of the target machine.
- **FR-009**: The configuration framework MUST produce valid target closures for all existing targets: desktop workstation, homelab server, and minimal installation media.
- **FR-010**: The configuration framework MUST provide multi-platform development shells, formatting tasks, and automated verification checks across all supported architectures (`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`).
- **FR-011**: All existing operational recipes in the task runner (`check`, `lint`, `fmt`, `build`, `switch`, `test`, `boot`, `build-iso`) MUST remain fully supported and functional with identical CLI interfaces.
- **FR-012**: All static linting, code formatting, dead code detection, and secret detection checks MUST pass with zero warnings or errors.
- **FR-013**: The migration MUST be executed as a single atomic conversion across all targets (`desktop-pc`, `homelab`, `iso`), fully replacing and removing legacy directory trees (`modules/nixos/`, `modules/home-manager/`, `machines/`).

### Key Entities

- **Feature (Aspect)**: A cohesive, named unit of configuration residing in domain subdirectories under `modules/` (e.g., `modules/desktop/`, `modules/services/`, `modules/core/`). Encapsulates system services, user packages, configurations, and static dotfiles required to deliver that capability.
- **Target (Machine/Host)**: A concrete deployable system instance declared in `modules/hosts/` (such as `desktop-pc`, `homelab`, or `iso`). Composed of hardware parameters, identity settings, and an explicit list of enabled Features.
- **Shared Identity & Configuration Context**: Centralized repository-wide parameters declared in `modules/core/vars.nix` (user identity, credentials, contact information) consumed across all features and targets via `config`.
- **Configuration Engine**: The top-level composition layer (`flake.nix` with `flake-parts` and `import-tree`) that discovers features, resolves dependencies, merges aspects, and produces deployable target closures and developer toolchains.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of defined target machines and bootable images successfully generate deployable system closures with zero build errors.
- **SC-002**: Adding a new capability requires modifying at most 2 files (the new feature file itself and the target machine's feature list), reducing file-touch overhead by at least 60% compared to the previous host-and-module structure.
- **SC-003**: 100% of feature modules in the `modules/` tree are loaded via automated discovery, requiring zero manual import statements in centralized index files.
- **SC-004**: 100% of existing functional capabilities (installed user applications, shell configurations, desktop environments, server services, container engines) remain operational with zero functional regression.
- **SC-005**: 100% of automated code validation checks, static linters, formatters, and security filters pass with zero errors and zero warnings.
- **SC-006**: Target build evaluation time remains within 10% of the pre-migration baseline.

## Assumptions

- **Single Primary User Scope**: The primary user identity (`laurent`) defined in the centralized identity configuration remains the default user context for desktop and server features across all machines. Standalone Home Manager outputs are out of scope for this migration.
- **Orchestration Framework**: The dendritic architecture will be implemented using the canonical, battle-tested `flake-parts` framework paired with automated directory tree discovery (`vic/import-tree`), adhering to established dendritic best practices in the Nix community.
- **Feature Organization**: Existing modules in `modules/nixos/` and `modules/home-manager/` will be consolidated into domain-grouped feature units under `modules/` (`modules/core/`, `modules/desktop/`, `modules/services/`, `modules/hosts/`).
- **Hardware Isolation**: Hardware configurations (e.g., `hardware-configuration.nix`) will remain isolated per machine under host declarations and injected into target closures alongside enabled feature sets.
- **Task Runner Stability**: All commands defined in the operational task runner (`justfile`) will be preserved so user habits and external CI workflows remain completely uninterrupted.
- **Constitution Alignment**: The architectural shift from host-centric directory segregation to dendritic feature organization will be documented, and constitution guidelines will be respected throughout the migration.
