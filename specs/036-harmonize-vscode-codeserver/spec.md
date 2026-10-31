# Feature Specification: Harmonized Visual Studio Code and Code Server Configurations

**Feature Branch**: `036-harmonize-vscode-codeserver`

**Created**: 2026-10-31

**Status**: Draft

**Input**: User description: "Mutualise les configurations de Visual Studio Code et Code Server. La configuration de Code Server sur `homelab` doit ressembler au maximum à la configuration de Visual Studio Code sur `dekstop-pc`. Minimise ou élimine le code dupliqué."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Editor Settings and Visual Experience (Priority: P1)

As a developer moving between working locally in Visual Studio Code on `desktop-pc` and remotely via Code Server in a web browser on `homelab`, I want both editing environments to share the exact same core editor settings, theme, ruler guides, formatting behavior, file associations, and display preferences, so that my development experience feels seamless and identical regardless of whether I edit code natively on my desktop or remotely through a browser.

**Why this priority**: Directly addresses the primary user request to make the Code Server environment on `homelab` mirror the Visual Studio Code setup on `desktop-pc` as closely as possible.

**Independent Test**: Open both Visual Studio Code on `desktop-pc` and Code Server via browser on `homelab`; inspect settings and visual styling to confirm both instances display the same color theme (Nord), line numbering behavior (relative), ruler lines (80, 88, 100, 120), format-on-save behavior, and file associations.

**Acceptance Scenarios**:

1. **Given** a user opening a file in Code Server on `homelab`, **When** the editor interface renders, **Then** the interface applies the Nord color theme, configured ruler lines, relative line numbering, and typography preferences matching Visual Studio Code on `desktop-pc`.
2. **Given** a file modification in Code Server on `homelab`, **When** the file is saved, **Then** automatic formatting on save and trailing newline cleanup trigger identically to the desktop editor.
3. **Given** files with custom extensions (such as `.bu`, `.container`, or `.ign`), **When** opened in either Code Server or Visual Studio Code, **Then** the file associations and syntax modes match across both environments.

---

### User Story 2 - Parity of Language Extensions and Developer Tooling (Priority: P1)

As a developer authoring configurations and code in Code Server on `homelab`, I want the same curated suite of extensions and language support tools installed and active as in Visual Studio Code on `desktop-pc` (including Nix language support, TOML syntax support, Markdown linting, and formatting tools), so that I have identical syntax assistance, diagnostics, and code formatting capabilities in both environments.

**Why this priority**: Essential for productivity; without extension and tool parity, writing and validating code in the remote browser IDE lacks the quality checks and language intelligence available on the desktop workstation.

**Independent Test**: Open a Nix file, a TOML file, and a Markdown file in Code Server on `homelab`; verify that syntax highlighting, language server diagnostics, and code formatting are active and behave identically to Visual Studio Code on `desktop-pc`.

**Acceptance Scenarios**:

1. **Given** Code Server is initialized on `homelab`, **When** checking installed and enabled extensions, **Then** the complete shared set of extensions (Nord theme, Markdown linting, Nix language support, and TOML support) is present and active.
2. **Given** an open Nix document in Code Server, **When** requesting document formatting, **Then** the shared Nix formatting tool executes successfully and formats the code consistently with `desktop-pc`.
3. **Given** an open Markdown file in Code Server, **When** editing markdown headings or lists, **Then** markdown linting diagnostics provide real-time feedback matching the desktop editor experience.

---

### User Story 3 - Single Source of Truth with Zero Configuration Duplication (Priority: P2)

As a repository maintainer and developer, I want all shared editor settings, language configurations, and extension declarations to be defined once in a single shared configuration source, so that modifying a preference, theme, or extension updates both Visual Studio Code and Code Server simultaneously without manual code duplication or configuration drift.

**Why this priority**: Eliminates boilerplate and future drift across hosts, ensuring maintenance overhead remains minimal as new settings and extensions are introduced.

**Independent Test**: Add or modify a shared setting or extension in the centralized configuration definition, evaluate both the desktop workstation and homelab server configurations, and verify that both target environments reflect the change without requiring redundant declarations.

**Acceptance Scenarios**:

1. **Given** a shared editor setting defined in the central configuration source, **When** configurations are built or evaluated for `desktop-pc` and `homelab`, **Then** the setting is included in both target environments from the single declaration.
2. **Given** an extension added to the shared extension list, **When** configurations are evaluated, **Then** the extension is provisioned for both Visual Studio Code on `desktop-pc` and Code Server on `homelab`.
3. **Given** the codebase inspection of editor configurations, **When** reviewing definitions for desktop and homelab editors, **Then** zero duplicate key-value pairs or extension definitions exist between the two host modules.

---

### User Story 4 - Persistent Settings and State Continuity Across Homelab Reboots (Priority: P3)

As a homelab administrator managing an impermanent root system, I want all shared Code Server settings, extension assets, and runtime state to persist across host reboots on persistent storage, so that the harmonized editor configuration is immediately ready without delays or missing settings after a system reboot.

**Why this priority**: Ensures reliable operational continuity on `homelab`, preventing tmpfs state resets from wiping shared configurations or cached extensions.

**Independent Test**: Verify that declarative settings and extension storage paths on `homelab` are linked or preserved under persistent storage, reboot or re-evaluate the service, and verify that the editor loads with all shared settings and extensions intact.

**Acceptance Scenarios**:

1. **Given** `homelab` running on an ephemeral root with state preservation, **When** the host reboots, **Then** shared Code Server configurations and extension directories remain accessible and intact.
2. **Given** a new system configuration activation on `homelab`, **When** the Code Server service starts or restarts, **Then** updated shared settings take effect cleanly.

---

### Edge Cases

- **Platform-Specific Font Rendering**: In a native desktop GUI editor, fonts installed on the host system are rendered directly. In a web-based code editor running inside a client browser, the font specified in editor settings (`FiraCode Nerd Font`) must be resolved by the client's web browser or fall back gracefully to system monospace fonts without breaking editor layout.
- **Extensions Incompatible with Web/Headless Architecture**: Certain extensions may rely on desktop-specific native binaries (e.g., Wayland clipboard integration). Any desktop-only capabilities must remain strictly scoped to the desktop environment, while universal extensions (syntax, formatters, themes, linters) are shared.
- **Read-Only Declarative Settings vs. User Interactive Tweaks**: If settings are managed declaratively, attempting to modify them interactively inside the web UI should either inform the user or persist changes without breaking the declarative baseline.
- **Impermanent Root State on Homelab**: On `homelab`, `/` is volatile tmpfs. Any configuration files placed in the user home directory must be either declaratively provisioned in the immutable system store / symlinked, or backed by persistent storage.
- **Host Architecture Differences**: `desktop-pc` uses Home Manager to manage user profiles and desktop environments, whereas `homelab` runs with Home Manager disabled (`enableHomeManager = false`). The shared configuration mechanism must be consumable by both Home Manager modules (desktop) and native system service modules (homelab) without coupling `homelab` to Home Manager.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST establish a centralized, shared editor configuration source that defines common user settings, visual appearance options, and extension lists for both Visual Studio Code and Code Server.
- **FR-002**: The shared configuration MUST include core editor behavior settings, including relative line numbering, ruler guidelines (80, 88, 100, 120 columns), format-on-save enablement, insertion of final newlines, and trimming of trailing newlines.
- **FR-003**: The shared configuration MUST include the Nord color theme as the default workbench theme across both Visual Studio Code on `desktop-pc` and Code Server on `homelab`.
- **FR-004**: The shared configuration MUST configure consistent typography preferences across editor buffers, integrated terminals, debug consoles, and source control input fields (specifying `FiraCode Nerd Font` with font ligatures enabled).
- **FR-005**: The shared configuration MUST define uniform file associations (including `.bu` as YAML, `.container` as INI, and `.ign` as JSON) and Git interaction preferences across both environments.
- **FR-006**: The shared configuration MUST configure language-specific settings and tooling for Nix and TOML, including tab size, format-on-paste, format-on-save, and formatting commands.
- **FR-007**: The system MUST provision the shared suite of compatible extensions (GitHub Actions, GitHub Pull Requests and Issues, Nord theme, Markdownlint, Nix language support, Alejandra formatter, and Even Better TOML) for both Visual Studio Code on `desktop-pc` and Code Server on `homelab`.
- **FR-008**: The system MUST eliminate duplicated setting values and duplicated extension lists between `modules/desktop/editors.nix` and `modules/services/code-server.nix`, referencing the shared configuration source instead.
- **FR-009**: The shared configuration MUST be consumable by `homelab` without requiring Home Manager to be enabled (`enableHomeManager = false` must remain preserved on `homelab`).
- **FR-010**: Desktop-specific components (such as Wayland clipboard utilities and Zed editor) MUST remain strictly scoped to `desktop-pc` and MUST NOT be introduced onto `homelab`.
- **FR-011**: On `homelab`, the shared Code Server settings and extensions MUST persist across host reboots through the persistent storage layer.
- **FR-012**: System documentation (`README.md`) MUST be updated to document the unified editor configuration and shared feature set, providing dual Bash and Fish command examples where applicable.

### Key Entities

- **Shared Editor Configuration**: The single source of truth containing common editor settings (display, formatting, typography, git, file associations, and language rules) and the list of universal extensions shared between desktop and web editors.
- **Desktop Visual Studio Code Profile**: The workstation-specific editor environment on `desktop-pc` that consumes the shared editor configuration within Home Manager and adds desktop-specific integrations.
- **Homelab Code Server Service**: The server-side web editor service on `homelab` that consumes the shared editor configuration natively without Home Manager, exposing the unified editing environment over HTTPS.
- **Persisted State Directories**: The directories on `homelab` (`~/.local/share/code-server` and `~/.config/code-server`) preserved across tmpfs reboots under persistent storage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of common editor settings (theme, typography preferences, ruler columns, save behaviors, file associations, and language formatting rules) are identical between Visual Studio Code on `desktop-pc` and Code Server on `homelab`.
- **SC-002**: 0 lines of duplicate editor settings JSON or duplicate extension lists exist between `desktop-pc` and `homelab` modules; all shared options are derived from a single configuration source.
- **SC-003**: 100% of shared extensions (GitHub Actions, GitHub Pull Requests and Issues, Nord theme, Markdownlint, Nix IDE/language support, Alejandra formatter, Even Better TOML) are installed and operational on both `desktop-pc` and `homelab`.
- **SC-004**: Both `desktop-pc` and `homelab` system configurations evaluate and build cleanly with 0 errors, with `homelab` continuing to evaluate with Home Manager disabled (`enableHomeManager = false`).
- **SC-005**: 100% of shared settings and installed extensions on `homelab` persist across system reboots on impermanent storage.
- **SC-006**: 100% pass rate on repository quality gates and static analysis checks (`just fmt`, `just lint`, `just check`).

## Assumptions

- **Shared User Account**: Both `desktop-pc` and `homelab` operate under the primary user account specified by `config.flake.vars.userName` (`laurent`).
- **Browser Font Fallback**: In Code Server web sessions, font rendering depends on the client device; declaring `FiraCode Nerd Font` in shared settings ensures that any client with the font installed will render ligatures and Nerd Font glyphs, while standard monospace serves as a safe browser fallback.
- **Headless Server Constraints**: `homelab` remains a headless server without graphical X11/Wayland sessions; any desktop GUI editors (e.g. Zed) or Wayland tools (`wl-clipboard`) remain exclusively in the desktop domain.
- **Extension Compatibility**: All extensions included in the shared suite are compatible with both Visual Studio Code and Code Server (built on VS Code open-source core).
- **Architectural Placement**: The shared configuration can reside in a cohesive shared module (such as a core or shared editor helper) that both `desktop.editors` and `services.code-server` import or reference, preserving the repository's dendritic pattern.
