# Feature Specification: Local Development and Deployment Stack on Homelab

**Feature Branch**: `029-homelab-dev-stack`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Je n'arrive pas à déployer la configuration du homelab depuis le homelab lui-même car `just` n'est pas disponible. Fais en sorte que la stack nécessaire au développement local soit installée sur `homelab`. Il suffit peut-être d'installer `direnv` pour activer l'environnement de développement décrit dans @flake.nix  ou @devbox.json"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Self-Hosted Configuration Deployment from Homelab (Priority: P1)

As a system administrator logged into `homelab` (via SSH, local console, or the self-hosted OpenCode interface), I want the command runner (`just`) and deployment utilities (`nh`) to be available on `homelab` so that I can build, test, and deploy configuration changes to `homelab` directly from the machine itself without relying on a separate workstation.

**Why this priority**: Currently, deploying configuration updates directly on `homelab` fails immediately because `just` is not installed in the system environment. Providing the core task runner and deployment tools directly unblocks local operations and self-deployment on `homelab`.

**Independent Test**: Connect to `homelab`, navigate to the repository workspace, and run `just --list` and `just test` (or `just check`) to verify that deployment and verification recipes execute without missing command errors.

**Acceptance Scenarios**:

1. **Given** an operator session on `homelab` (in either Fish or Bash), **When** the operator runs `just --list` inside the configuration repository, **Then** the command succeeds and displays all available operational recipes.
2. **Given** a configuration change in the repository on `homelab`, **When** the operator runs `just test` or `just switch`, **Then** the system builds and activates the `homelab` configuration locally without requiring an external machine.
3. **Given** an automated or interactive coding session via the OpenCode service on `homelab`, **When** the session invokes `just` recipes to validate or apply changes, **Then** the required CLI tools are accessible in the execution environment.

---

### User Story 2 - Automatic Development Environment Activation via Direnv (Priority: P2)

As a developer working inside the configuration repository on `homelab`, I want `direnv` (with persistent Nix flake caching) enabled and integrated into the system shells so that entering the repository directory automatically activates the full development environment (linters, formatters, secret scanners, and pre-commit hooks) defined by the project flake.

**Why this priority**: Rather than manually running `nix develop` before every work session or duplicating every development package globally, automatic environment activation via `direnv` guarantees that entering the workspace immediately loads the exact pinned tools and pre-commit hooks defined in the repository's flake development shell.

**Independent Test**: Log into `homelab`, navigate into the repository directory containing `.envrc`, run `direnv allow` once, and confirm that the flake development shell loads automatically and provides all quality gate tools (`alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`).

**Acceptance Scenarios**:

1. **Given** `direnv` is enabled on `homelab`, **When** the user navigates into the repository directory and authorizes it with `direnv allow`, **Then** the development environment defined in the repository is automatically loaded into the current shell session (both Fish and Bash).
2. **Given** an active `direnv` session inside the repository on `homelab`, **When** the user runs `just fmt`, `just lint`, or `just check`, **Then** all formatting, static analysis, and secret scanning tools execute seamlessly.
3. **Given** `homelab`'s ephemeral root filesystem (`tmpfs` with state preservation), **When** the user authorizes a workspace with `direnv allow` and reboots `homelab`, **Then** the `direnv` authorization and cached environment state persist across reboots without requiring re-authorization.

---

### User Story 3 - Shared Core Developer Tooling Across Hosts (Priority: P3)

As a maintainer managing multiple machines (`desktop-pc`, `homelab`, and `macbook-air-m4-15`), I want foundational developer environment capabilities (`direnv` with Nix flake integration and core operational tools) to be organized consistently without unnecessary duplication between workstation and server configurations, and documented clearly in the project documentation.

**Why this priority**: Keeps the architecture aligned with the repository's modular design principles and ensures documentation accurately reflects how local development and deployment work across all hosts.

**Independent Test**: Evaluate and build the configurations for all repository hosts (`homelab`, `desktop-pc`, `macbook-air-m4-15`, `iso`) and verify that `README.md` documents the `homelab` local development and deployment capabilities with dual Bash/Fish instructions where applicable.

**Acceptance Scenarios**:

1. **Given** the repository's host configurations, **When** evaluating `homelab`, `desktop-pc`, and `macbook-air-m4-15`, **Then** all hosts build cleanly and provide `direnv`, `just`, and `nh` without conflicting definitions.
2. **Given** the project `README.md`, **When** a user reviews the host capabilities and deployment instructions, **Then** the documentation accurately reflects the availability of the local development stack and `direnv` on `homelab`.

---

### Edge Cases

- **Ephemeral Root Filesystem on Homelab**: Because `homelab` runs on an ephemeral `tmpfs` root with explicit state preservation, what happens to `direnv` allow-lists after a reboot? The user's `.local/share/direnv` directory must be preserved in persistent storage so approved `.envrc` files remain trusted across reboots.
- **Running `just` Before `direnv allow` or in Non-Interactive Shells**: What happens if an operator or background service (such as `opencode-web`) runs `just` inside the repository before `direnv allow` has been executed interactively, or from a non-interactive process that does not trigger shell prompt hooks? Having `just`, `nh`, and `direnv` installed directly in the system environment ensures baseline deployment and task runner commands work immediately in both interactive and non-interactive contexts.
- **Dual-Shell Support (Fish and Bash)**: What happens when switching between the default interactive Fish shell and Bash on `homelab`? System-level `direnv` integration automatically hooks into both Fish and Bash shells so `.envrc` activation works regardless of which shell the operator uses.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST enable `direnv` with fast, persistent Nix flake environment evaluation (`nix-direnv`) on `homelab` (and shared across NixOS hosts) with automatic shell integration for both Fish and Bash.
- **FR-002**: System MUST provide `just` and `nh` directly in the system environment so operators can run `just` operational and deployment recipes (`just switch`, `just test`, `just check`, etc.) on `homelab` immediately, even prior to interactive `.envrc` activation.
- **FR-003**: System MUST ensure the OpenCode background web service (`opencode-web`) on `homelab` has access to the necessary CLI tools (`just`, `nh`, `direnv`, `nix`) in its execution path so agent sessions can validate and deploy configurations locally.
- **FR-004**: System MUST persist user `direnv` state and allow-lists (`~/.local/share/direnv`) across reboots on hosts using ephemeral root storage (`core.preservation`).
- **FR-005**: System MUST maintain full compatibility with existing workstation configurations (`desktop-pc` and `macbook-air-m4-15`) without introducing duplicate or conflicting option definitions.
- **FR-006**: System MUST update `README.md` to document the local development and self-deployment stack available on `homelab`, providing both Bash and Fish command variants where shell syntax differs.
- **FR-007**: All configuration changes MUST pass repository formatting (`just fmt`), static analysis (`just lint`), and flake check (`just check`) quality gates with zero errors or warnings.

### Key Entities

- **Development Environment Activation (`direnv` / `.envrc`)**: The mechanism that detects the repository's `.envrc` (`use flake`) and automatically loads the pinned development tools (`just`, `nh`, `alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`, `pre-commit`) into the user's shell.
- **Baseline System Development Stack**: The foundational CLI tools (`direnv`, `nix-direnv`, `just`, `nh`) installed at the system level so local deployment and environment activation are always available on `homelab`.
- **Persistent Direnv State**: The user's `~/.local/share/direnv` directory preserved across reboots on ephemeral-root hosts to retain trusted `.envrc` authorizations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operators on `homelab` can execute `just` recipes (`just --list`, `just check`, `just test`, `just switch`) directly from a terminal or SSH session with a 100% command availability rate.
- **SC-002**: Entering the repository directory on `homelab` after running `direnv allow` once automatically activates the development shell in 100% of interactive Fish and Bash sessions without manually invoking `nix develop`.
- **SC-003**: 100% of `direnv allow` workspace authorizations on `homelab` survive system reboots without requiring manual re-authorization.
- **SC-004**: 100% of repository quality gates (`just fmt`, `just lint`, `just check`) and host evaluations (`homelab`, `desktop-pc`, `macbook-air-m4-15`, `iso`) pass with exit code 0.

## Assumptions

- The repository already defines `.envrc` with `use flake` and a complete `devShells.default` in `modules/core/devshell.nix` containing `just`, `nh`, and all pre-commit verification tools (`alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`).
- Using NixOS native `programs.direnv` (which enables `nix-direnv` by default when `programs.direnv.enable = true`) together with baseline packages (`just`, `nh`) satisfies the user's requirement without needing to install a separate third-party container/sandbox manager like `devbox` on NixOS, since NixOS natively evaluates `flake.nix` via `use flake`.
- Placing `direnv`, `just`, and `nh` in the shared base configuration (or core module) benefits all NixOS/Darwin hosts while keeping `homelab` lightweight and headless (`enableHomeManager = false`).
