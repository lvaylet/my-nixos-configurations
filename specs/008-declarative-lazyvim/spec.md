# Feature Specification: Declarative LazyVim Configuration

**Feature Branch**: `008-declarative-lazyvim`

**Created**: 2026-10-12

**Status**: Draft

**Input**: User description: "Implémente une version déclarative de LazyVim compatible avec NixOS. Installe toutes les dépendances listées dans la section Getting Started de <https://www.lazyvim.org/> et réplique la configuration de base de <https://github.com/LazyVim/starter>"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Out-of-the-Box Modal Editing with LazyVim Starter (Priority: P1)

As a developer using the desktop system, I want to launch the editor from the terminal and immediately interact with a fully functional, responsive LazyVim environment mirroring the official LazyVim starter baseline (including starter dashboard, default keybindings, sensible options, file exploration, status line, and fuzzy finding), so that I can perform code editing tasks immediately without manual editor setup.

**Why this priority**: Core user journey and primary value proposition. Without a functioning baseline editor out of the box, subsequent customizations or development tasks cannot be performed.

**Independent Test**: Can be tested by launching the editor in a terminal via standard command (`nvim`), verifying that the LazyVim starter interface loads without error messages, verifying default keybindings and options behave as expected, and confirming that creating and modifying a document succeeds.

**Acceptance Scenarios**:

1. **Given** a newly provisioned or updated system environment, **When** the user executes the editor command (`nvim`, `vi`, or `vim`) in a terminal, **Then** the editor starts with the complete LazyVim starter user interface, theme, and statusline with no configuration errors or missing plugin warnings.
2. **Given** an active editor session, **When** the user invokes default LazyVim keybindings (such as opening the file browser, searching for files, or toggling buffers), **Then** the expected interface overlays appear promptly and perform the requested navigation.
3. **Given** an active editor session, **When** the user navigates and edits files, **Then** baseline editor behaviors (line numbers, indentation rules, clipboard integration, undo history) function consistently according to the starter specification.

---

### User Story 2 - Comprehensive Availability of Upstream Runtime Dependencies (Priority: P1)

As a developer, I want all external command-line dependencies mandated by LazyVim's upstream Getting Started documentation (modern editor binary, Git, C compiler, fast file finder, fast text search engine, and Nerd Font iconography) to be automatically present and integrated in the execution environment, so that all editor features (file search, grep search, on-demand syntax parsing, and plugin operations) work seamlessly without imperative package installations.

**Why this priority**: LazyVim relies on external system utilities for essential features like file indexing, project-wide text search, and Tree-sitter parser compilation. Without these dependencies, editor features fail silently or crash.

**Independent Test**: Can be tested by running project-wide file search and text search within the editor on a sample codebase, opening a file requiring syntax tree compilation, and checking that search results and syntax highlighting work without missing-binary errors.

**Acceptance Scenarios**:

1. **Given** an open project directory, **When** the user triggers project-wide file finding or text search in the editor, **Then** the search executes using fast system search utilities without prompting for missing binaries.
2. **Given** a source code file opened in the editor, **When** syntax tree parsers are loaded or compiled, **Then** the C compiler toolchain is available in the execution path and compiles the necessary syntax parsers without errors.
3. **Given** a Git repository workspace, **When** the user performs version control queries or uses editor Git integrations, **Then** the version control client functions transparently without errors.
4. **Given** a terminal session displaying the editor interface, **When** status icons, file types, and indicators are rendered, **Then** modern Nerd Font glyphs render crisply without missing font artifacts or unrendered glyph boxes.

---

### User Story 3 - Declarative Customization and Extension Workflow (Priority: P2)

As a developer, I want to add custom plugins, adjust keymaps, and modify editor settings using standard LazyVim starter layout conventions (`lua/config/` and `lua/plugins/`), so that I can personalize my editing environment declaratively without breaking upstream upgrade paths.

**Why this priority**: Developers need custom toolchains, plugins, and keybindings suited to their workflows, but customizations must remain isolated and clean according to LazyVim conventions.

**Independent Test**: Can be tested by adding a custom plugin configuration file and a custom keybinding under the designated configuration structure, rebuilding the configuration, and verifying that the custom plugin and keybinding are active and effective in the editor.

**Acceptance Scenarios**:

1. **Given** a custom plugin definition placed in the designated plugin configuration directory, **When** the editor is launched, **Then** the custom plugin is detected, enabled, and functions according to its specification.
2. **Given** custom keymaps defined in the designated keymaps configuration file, **When** the key combinations are pressed in the editor, **Then** the custom actions are executed without overriding essential system shortcuts.
3. **Given** custom option tweaks defined in the options configuration file, **When** the editor initializes, **Then** the custom options take precedence over default starter values.

---

### User Story 4 - Hermetic System Integration and State Isolation (Priority: P2)

As a system maintainer, I want the LazyVim environment to be managed entirely via the system's declarative module architecture, with configuration tracked in version control and mutable cache/state directories isolated, so that configurations reproduce deterministically across machines without drift.

**Why this priority**: Aligns directly with system constitution principles of reproducibility, hermetic configuration, and clean separation between immutable declarations and transient runtime state.

**Independent Test**: Can be tested by evaluating the system configuration build, verifying that the editor module compiles cleanly into the host target, and verifying that rebuilding or deploying on another system reproduces the identical editor configuration without manual onboarding steps.

**Acceptance Scenarios**:

1. **Given** the declarative system configuration, **When** the desktop editors module is evaluated, **Then** the LazyVim configuration is integrated cleanly and passes all evaluation checks.
2. **Given** system rebuilds across multiple generations, **When** the editor configuration is unmodified, **Then** the generated editor configuration files remain identical.
3. **Given** runtime usage that creates temporary editor swap files, undo trees, and plugin caches, **When** transient state is created, **Then** it is contained within designated user state paths without polluting version-controlled directories or causing declarative divergence.

---

### Edge Cases

- **Offline First Launch**: If the system is initialized or launched without internet access before initial plugin dependencies are cached, the editor must handle network unavailability gracefully, launching into a usable fallback editing mode and alerting the user rather than freezing or crashing.
- **Preexisting or Conflicting Neovim Configuration**: If preexisting imperative Neovim configuration files exist in the user's home directory, the declarative configuration system must cleanly manage ownership or replace/isolate the legacy configuration without corrupted hybrid states.
- **Missing Terminal True-Color or Font Support**: If launched within a minimal terminal that lacks true-color or Nerd Font support, the editor interface must remain navigable and functional in plain text mode without unreadable scrambled control characters.
- **Incompatible User Plugin Definition**: If a user introduces a malformed or broken Lua plugin specification in their custom plugins directory, the editor must report the specific syntax or runtime error in a diagnostic window without aborting the entire editor startup process.
- **Large Repository Search Under Heavy Load**: When executing fuzzy search or text search over very large codebases (tens of thousands of files or large binary files), search tools must respect default ignore patterns to avoid freezing editor responsiveness.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an integrated LazyVim code editing environment accessible from the terminal using the standard `nvim` command.
- **FR-002**: The system MUST provide the full directory and file organization of the upstream LazyVim starter baseline, including entrypoint initialization (`init.lua`), core configuration modules (`options.lua`, `keymaps.lua`, `autocmds.lua`, `lazy.lua`), and dedicated user plugin directories (`plugins/`).
- **FR-003**: The system MUST automatically install and make available all runtime dependencies identified in the upstream LazyVim Getting Started documentation:
  - Modern Neovim runtime version 0.9.0 or higher built with LuaJIT support.
  - A modern version control tool (Git version 2.19.0 or higher) for repository and plugin operations.
  - A C compiler toolchain capable of compiling Tree-sitter language grammars on demand.
  - A high-performance text search tool (ripgrep) for live search and project-wide pattern matching.
  - A fast filesystem search utility (fd) for fuzzy file discovery and navigation.
- **FR-004**: The system MUST ensure the host terminal environment and graphical font configuration provide modern Nerd Font glyph rendering (v3.0+) and 24-bit true-color display for the editor.
- **FR-005**: The system MUST manage the LazyVim baseline and starter files declaratively, ensuring the editor configuration is completely reproduced across system installations and host rebuilds.
- **FR-006**: The system MUST support user-defined plugin extensions and configuration overrides placed in dedicated modular files within the configuration hierarchy without modifying core upstream baseline files.
- **FR-007**: The system MUST isolate mutable runtime data (such as plugin repositories, cache files, undo history, and swap data) into designated transient user state directories (`~/.local/share` and `~/.cache`), preventing runtime state from mutating declarative source files.
- **FR-008**: The editor configuration MUST be structured as a modular capability within the repository's desktop module domain and composed into eligible desktop host specifications.
- **FR-009**: The system MUST configure default aliases so that invoking `vi` or `vim` launches the declarative LazyVim environment.

### Key Entities

- **LazyVim Baseline Configuration**: The declarative set of upstream configuration files derived from the LazyVim starter repository, establishing core options, standard keybindings, autocommands, and baseline plugin manager configuration.
- **Runtime Dependency Bundle**: The suite of host CLI tools (Neovim, Git, C compiler, ripgrep, fd) required to execute the editor and its auxiliary indexing and parsing subsystems.
- **User Plugin Extension**: An isolated Lua module located in the user plugins directory allowing developers to add, configure, or disable specific plugins while inheriting the baseline starter configuration.
- **Transient State Store**: The user-scoped filesystem storage holding runtime caches, downloaded plugin sources, tree-sitter compiled objects, and editing history, separated from the declarative configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The editor launches and displays an interactive editing screen within 1.0 second on standard desktop hardware.
- **SC-002**: 100% of the runtime dependencies specified in upstream LazyVim documentation (text search, file search, compiler, version control client) are available and executable from the editor environment without manual path configuration.
- **SC-003**: A newly deployed or rebuilt host environment provides a functional LazyVim setup in a single build operation, requiring 0 manual shell setup commands.
- **SC-004**: Project file search operations across a workspace containing 10,000+ files display initial search results within 500 milliseconds.
- **SC-005**: 100% of baseline starter keybindings (e.g. file browsing, buffer management, fuzzy search) perform their expected operations upon initial startup.
- **SC-006**: New user plugin specifications added to the user plugin directory load successfully on the subsequent editor start with zero manual registration steps.
- **SC-007**: The host system configuration evaluates cleanly with 0 syntax or composition errors when the LazyVim feature is enabled.

## Assumptions

- The target system is a desktop workstation running a Wayland/X11 graphical environment with a compatible terminal emulator configured with Nerd Fonts and true-color support.
- The editor environment has access to the internet during initial plugin retrieval, or utilizes existing cached plugin state when operating offline.
- The declarative LazyVim setup will supersede or replace the existing editor module setup in `modules/desktop/editors.nix` for the desktop host.
- Dynamic plugin downloads and cache artifacts managed by the plugin manager are classified as transient runtime state (stored under standard user data and cache paths) in accordance with project Constitution Principle I.
- The default configuration maintains upstream LazyVim starter keymap standards, which users can customize by adding overrides to their configuration files.
