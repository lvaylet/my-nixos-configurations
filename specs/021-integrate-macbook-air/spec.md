# Feature Specification: Integrate MacBook Air M4 Host and Mutualize Shared Configurations

**Feature Branch**: `021-integrate-macbook-air`

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "Je viens d'acquérir un MacBook Air M4. Je souhaite réutiliser un maximum d'applications, de services et de paramètres de `desktop-pc` et `homelab`. Aide-moi à identifier les parties réutilisables et à les mutualiser. Le nouvel hôte s'appellera `macbook-air-m4-15`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Shared User Environment & Productivity Tools on `macbook-air-m4-15` (Priority: P1)

As a developer using the newly acquired MacBook Air M4 (`macbook-air-m4-15`), I want my daily user environment—including the interactive Fish shell, Starship prompt, system and shell aliases, Git and LazyGit configurations, Neovim/LazyVim editor, terminal emulators (Ghostty, WezTerm), VS Code settings, and core CLI utilities—to be shared seamlessly with my existing workstation configuration (`desktop-pc`), so that I get an identical, familiar, and highly productive developer experience across both machines without duplicating configuration files.

**Why this priority**: Daily developer ergonomics and consistency across workstations are the primary motivation for integrating a new machine; having matching shell workflows, shortcuts, and editor tooling eliminates cognitive friction when moving between devices.

**Independent Test**: Build and activate the user environment on `macbook-air-m4-15`, open an interactive terminal, verify that Fish starts with the Starship prompt, that custom aliases (`ls`, `cat`, `y`, `b`) behave identically to `desktop-pc`, that Git and LazyGit reflect the user's identity and Nord theme, and that Neovim and VS Code launch with identical plugins and configurations.

**Acceptance Scenarios**:

1. **Given** an active session on `macbook-air-m4-15`, **When** the user opens an interactive shell, **Then** Fish launches with the Starship prompt, Nord theme palette, and all standard shortcuts and aliases shared with `desktop-pc`.
2. **Given** the user environment on `macbook-air-m4-15`, **When** launching `nvim` or `code`, **Then** both editors load the shared configurations, font settings (FiraCode Nerd Font), syntax tools, and themes without requiring manual setup.
3. **Given** any Git repository on `macbook-air-m4-15`, **When** inspecting Git configuration or launching `lazygit`, **Then** user identity, pull/rebase policies, diff histogram settings, and the custom LazyGit visual styling match the existing workstation setup.

---

### User Story 2 - Declarative Host Definition & Cross-Platform Modularity (Priority: P1)

As a system administrator and repository maintainer, I want a declarative host definition named `macbook-air-m4-15` integrated into the repository using the dendritic architecture, so that common features are factored into shared, platform-aware modules, while platform-specific aspects (macOS on Apple Silicon vs. Linux on x86_64) remain isolated without causing evaluation conflicts or regressions on `desktop-pc` or `homelab`.

**Why this priority**: Enforces repository architectural integrity (Constitution Principle II) and prevents cross-platform collisions between macOS (`aarch64-darwin`) and Linux (`x86_64-linux`), ensuring existing machines continue to build and evaluate cleanly.

**Independent Test**: Evaluate the repository configuration for all targets (`desktop-pc`, `homelab`, `iso`, and `macbook-air-m4-15`) using automated checks (`just check`); verify that all hosts evaluate cleanly without errors, warnings, or cross-platform path incompatibilities.

**Acceptance Scenarios**:

1. **Given** the repository with the new host definition, **When** running repository-wide evaluation and check gates, **Then** the flake successfully builds and evaluates configurations for `desktop-pc`, `homelab`, `iso`, and `macbook-air-m4-15`.
2. **Given** shared modules between Linux and macOS hosts, **When** evaluating on macOS, **Then** platform-incompatible components (such as Linux-specific systemd units, Wayland compositors, and kernel drivers) are cleanly excluded from `macbook-air-m4-15` without requiring duplicate module files.
3. **Given** paths to user configuration files, **When** evaluated on `macbook-air-m4-15`, **Then** standard cross-platform conventions (`$HOME` / `/Users/<username>` vs `/home/<username>`) are honored automatically.

---

### User Story 3 - Homelab Connectivity & Remote Client Access (Priority: P2)

As a remote user on `macbook-air-m4-15`, I want preconfigured client access to the services running on `homelab`—including SSH client definitions, Tailscale mesh networking, and quick access to hosted web applications—so that I can manage and utilize homelab infrastructure directly from my laptop whether on the local network or traveling.

**Why this priority**: The MacBook Air is a mobile client device; enabling immediate, secure connection to the central `homelab` server ensures operational access from anywhere without manual network configuration.

**Independent Test**: Inspect the SSH client configuration on `macbook-air-m4-15`, verify that `ssh homelab` resolves to the configured target IP/hostname and correct identity key, and verify that Tailscale is declared for secure mesh connectivity.

**Acceptance Scenarios**:

1. **Given** the activated user profile on `macbook-air-m4-15`, **When** the user runs `ssh homelab`, **Then** the SSH client uses the preconfigured host definition (correct target address, user identity, and key path) shared from the repository.
2. **Given** secure network configuration, **When** the laptop connects to the Tailscale mesh, **Then** `macbook-air-m4-15` can securely communicate with `homelab` services.

---

### User Story 4 - Living Documentation & Dual-Shell Parity (Priority: P2)

As a contributor or operator setting up `macbook-air-m4-15`, I want `README.md` to clearly document the new host, its architecture, the inventory of mutualized vs. host-specific features, and the exact provisioning commands with both Bash and Fish variants, so that onboarding and maintaining the MacBook Air is fully documented and reproducible.

**Why this priority**: Fulfills Constitution Principle VI (*Living Documentation & Dual-Shell Parity*), preventing documentation drift and guaranteeing copy-paste accuracy during initial setup and subsequent updates.

**Independent Test**: Review `README.md` to ensure `macbook-air-m4-15` is included in the host inventory and architecture diagrams, and verify that all bootstrap, testing, and deployment commands for macOS provide explicit Bash and Fish variants.

**Acceptance Scenarios**:

1. **Given** the updated documentation, **When** reading the host inventory in `README.md`, **Then** `macbook-air-m4-15` is documented with its target architecture (`aarch64-darwin`), role, and enabled feature modules.
2. **Given** any operational command for building or switching `macbook-air-m4-15`, **When** executed in either a Bash or Fish shell, **Then** copy-paste ready snippets are provided for both shells.

---

### Edge Cases

- **Home Directory Path Differences**: macOS uses `/Users/<username>` while Linux NixOS uses `/home/<username>`. Shared modules referencing user dotfiles or configurations must rely on environment-aware expressions (e.g., `home.homeDirectory` or dynamic user paths) and must not hardcode `/home/`.
- **System-level vs. User-level Separation**: System services native to Linux (such as systemd services, Podman system daemons, Caddy, Jellyfin) cannot run natively via NixOS module declarations on macOS. Modules containing both system and user configurations must cleanly separate them so only user-level declarations are consumed by the macOS target.
- **Wayland / Linux-specific Tools**: Utilities like `wl-clipboard` or Linux filesystem utilities (`efibootmgr`, `parted`) must not be installed on macOS where native equivalents (`pbcopy`/`pbpaste`, native diskutil) are standard.
- **Graphical Applications on macOS**: Certain graphical applications (like Chrome or Obsidian) can be managed natively on macOS; declarations should ensure compatible package derivations or system-appropriate package channels are used for `aarch64-darwin`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST define a new host named `macbook-air-m4-15` targeting the Apple Silicon macOS architecture (`aarch64-darwin`).
- **FR-002**: The host configuration for `macbook-air-m4-15` MUST adhere to the dendritic architecture under `modules/hosts/`, composing shared modules without inline service or environment declarations.
- **FR-003**: The interactive shell configuration (`desktop.shell`) MUST be shared between `desktop-pc` and `macbook-air-m4-15`, providing the same Fish settings, Nord palette, Starship prompt, and command aliases across both machines.
- **FR-004**: The Git and LazyGit configurations (`core.git`) MUST be shared across `desktop-pc` and `macbook-air-m4-15`, guaranteeing identical identity, diff settings, and visual themes.
- **FR-005**: The Neovim and LazyVim configuration (`core.neovim`) MUST be shared across all hosts (`desktop-pc`, `homelab`, and `macbook-air-m4-15`), deploying the shared dotfiles without relying on Linux-only primitives (such as `systemd.tmpfiles.rules`) or hardcoded `/home/` paths.
- **FR-006**: Code editor configurations (`desktop.editors`), terminal emulator settings (`desktop.terminal`, `desktop.apps`), and core developer CLI utilities (e.g., `bat`, `btop`, `eza`, `fzf`, `jq`, `ripgrep`, `yazi`, `just`, `direnv`, `alejandra`, `statix`, `deadnix`) MUST be shared and enabled on `macbook-air-m4-15`.
- **FR-007**: Linux-specific graphical display components (Niri Wayland compositor, Greetd display manager, Noctalia shell, NVIDIA graphics drivers, PipeWire audio) MUST remain restricted to Linux desktop hosts and MUST NOT be imported into `macbook-air-m4-15`.
- **FR-008**: Server-side infrastructure services (Caddy reverse proxy, Jellyfin, AdGuard Home, Portainer, qBittorrent, n8n, WAHA, Uptime Kuma) MUST remain confined to the `homelab` server and MUST NOT be instantiated as local daemons on `macbook-air-m4-15`.
- **FR-009**: The SSH client module (`services.ssh`) MUST be shared to provide `macbook-air-m4-15` with preconfigured host aliases and connection parameters for `homelab`.
- **FR-010**: Centralized user identity options (`core.vars`) MUST be reused by `macbook-air-m4-15` for username, full name, email, and SSH public key attributes.
- **FR-011**: All repository quality gates (`just fmt`, `just lint`, `just check`) MUST pass with exit code 0 across all defined targets, with zero evaluation warnings or errors on both Linux and macOS targets.
- **FR-012**: `README.md` MUST be updated within the feature branch to document `macbook-air-m4-15`, its mutualized components, and operational commands with strict dual Bash/Fish syntax parity.

### Key Entities

- **Host Target (`macbook-air-m4-15`)**: A declared system target representing the Apple Silicon MacBook Air running macOS, composing shared user features and client services.
- **Shared User Environment**: The collection of cross-platform configurations (shell, prompt, editor dotfiles, Git, terminal settings, CLI tools) reusable across both Linux workstations and macOS laptops.
- **Remote Service Gateway**: The client configuration profile (SSH aliases, network mesh coordinates) allowing the portable laptop to interact with the static homelab server.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of portable developer tools and dotfiles (Fish, Starship, Git, LazyGit, Neovim, WezTerm, Ghostty, VS Code settings, and core CLI utilities) are reused on `macbook-air-m4-15` with zero duplicate configuration declarations.
- **SC-002**: Automated flake validation (`just check`) and static analysis (`just lint`, `just fmt`) succeed with a 100% pass rate across all declared configurations (`desktop-pc`, `homelab`, `iso`, and `macbook-air-m4-15`).
- **SC-003**: An operator executing `ssh homelab` on `macbook-air-m4-15` connects directly to the homelab server in a single command using declarative SSH alias settings without manual flags.
- **SC-004**: 100% of operational instructions, bootstrapping procedures, and deployment recipes for `macbook-air-m4-15` in `README.md` provide dual-shell (Bash and Fish) command parity.

## Assumptions

- The MacBook Air M4 runs macOS (Darwin) as its primary operating system on the `aarch64-darwin` architecture.
- Declarative configuration on macOS will leverage Darwin-compatible mechanisms (such as `nix-darwin` and/or Home Manager for macOS) integrated cleanly with the repository's dendritic module pattern.
- Native macOS applications not packaged or suited for Nix derivation on Darwin can be managed via declarative package managers (e.g. Homebrew integration where applicable) or left to user preference.
- System services hosted on `homelab` remain centralized on the homelab hardware; the laptop interacts with them as a client over local network or Tailscale mesh.
