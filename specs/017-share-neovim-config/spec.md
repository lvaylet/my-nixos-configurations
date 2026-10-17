# Feature Specification: Shared System-Level Neovim Configuration Across Desktop and Homelab

**Feature Branch**: `017-share-neovim-config`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "Mets en place la mutualisation de Neovim entre `desktop-pc` et `homelab` sur la base de la réponse que tu viens de me donner."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Neovim & LazyVim Experience on Both Desktop and Homelab (Priority: P1)

As a system administrator and developer working across both `desktop-pc` and `homelab`, I want to launch `nvim`, `vi`, or `vim` in a terminal (locally on `desktop-pc` or over SSH on `homelab`) and get the exact same declarative LazyVim editing environment and runtime tools without requiring Home Manager on `homelab`, so that I have a consistent, full-featured modal editor on every managed machine.

**Why this priority**: Directly delivers the core value requested by the user: sharing the existing `desktop-pc` Neovim configuration with `homelab` while respecting `homelab`'s Home Manager-free architecture.

**Independent Test**: Connect to `homelab` (or test the evaluated `homelab` and `desktop-pc` configurations) and launch `nvim`, `vi`, and `vim`; verify that the LazyVim starter configuration loads from `~/.config/nvim`, `$EDITOR` defaults to `nvim`, and all required search and build utilities (`rg`, `fd`, `gcc`, `make`, `tree-sitter`, `git`) are available in `PATH`.

**Acceptance Scenarios**:

1. **Given** a deployed or updated `homelab` or `desktop-pc` host, **When** the user runs `nvim`, `vi`, or `vim`, **Then** the editor launches with the shared LazyVim configuration, aliases resolve to Neovim without package conflicts, and `$EDITOR` is set to Neovim.
2. **Given** an active editor session on `homelab` (where Home Manager is disabled) or `desktop-pc`, **When** the user uses fuzzy file finding, live text grep, or opens a file requiring syntax parser compilation, **Then** the required external tools (`fd`, `ripgrep`, `gcc`, `gnumake`, `tree-sitter`, `git`, archive utilities) and language providers (Node.js and Python 3) execute without missing-dependency errors.
3. **Given** the declarative dotfiles directory in the repository, **When** the system configuration is activated on either host, **Then** `~/.config/nvim` for the primary user points directly to the shared declarative Neovim configuration in the read-only system store without relying on Home Manager's `xdg.configFile`.

---

### User Story 2 - Persistent Neovim Plugins and Editor State Across Homelab Reboots (Priority: P1)

As a homelab administrator operating an impermanent root filesystem on `homelab`, I want installed LazyVim plugins, the plugin lockfile (`lazy-lock.json`), compiled Tree-sitter parsers, and editor state (undo history, ShaDa registers) to persist across system reboots, so that launching Neovim after a reboot is instantaneous and does not re-download plugins or recompile parsers every time `homelab` restarts.

**Why this priority**: `homelab` uses root filesystem impermanence (`preservation`). Without persisting Neovim's data and state directories, every reboot wipes `~/.local/share/nvim` and `~/.local/state/nvim`, causing network downloads, compilation delays, and lost editing history on every boot.

**Independent Test**: Launch `nvim` on `homelab` so plugins and parsers initialize in `~/.local/share/nvim` and state is written to `~/.local/state/nvim`, reboot `homelab`, and launch `nvim` again to verify that all plugins, lockfile, compiled parsers, and command/file history remain present immediately without re-cloning.

**Acceptance Scenarios**:

1. **Given** `homelab` has initialized its LazyVim plugins and Tree-sitter parsers in `~/.local/share/nvim`, **When** the `homelab` host reboots, **Then** `~/.local/share/nvim` (including `lazy/`, `lazy-lock.json`, and `treesitter/`) is preserved on persistent storage and available immediately upon login.
2. **Given** a user edits files in Neovim on `homelab` generating ShaDa history and undo state in `~/.local/state/nvim`, **When** the `homelab` host reboots, **Then** `~/.local/state/nvim` is preserved and recent files, registers, and undo history remain intact.

---

### User Story 3 - Clean Modular Separation Between Shared Core Editor and Desktop GUI Editors (Priority: P2)

As a maintainer of the repository's modular architecture, I want the shared Neovim configuration to live in a dedicated core module (`core.neovim`) while graphical desktop editors (VS Code, Zed) and Wayland clipboard utilities (`wl-clipboard`) remain scoped to the desktop editors module (`desktop.editors`), so that `homelab` stays free of graphical desktop dependencies while avoiding any duplication of Neovim settings.

**Why this priority**: Preserves the repository's feature-centric modularity and ensures headless server hosts (`homelab`) do not pull in desktop GUI packages or Home Manager modules.

**Independent Test**: Evaluate both `desktop-pc` and `homelab` system configurations and verify that both include `core.neovim`, `homelab` remains with `enableHomeManager = false` and no GUI editor packages, and `desktop-pc` retains VS Code, Zed, and `wl-clipboard`.

**Acceptance Scenarios**:

1. **Given** the `homelab` host configuration, **When** it is evaluated with `core.neovim` enabled, **Then** `enableHomeManager` remains `false` and no desktop GUI editors (VS Code, Zed) or Wayland-specific utilities (`wl-clipboard`) are installed on `homelab`.
2. **Given** the `desktop-pc` host configuration, **When** it is evaluated with both `core.neovim` and `desktop.editors` enabled, **Then** the user receives the shared system-level Neovim setup alongside Wayland clipboard integration (`wl-clipboard`) and desktop GUI editors (VS Code, Zed) with zero duplicate or conflicting Neovim definitions.

---

### Edge Cases

- **Binary Collision Between Standalone `vim` and Neovim `vimAlias`**: If `vim` is listed in base system packages while Neovim's `vimAlias = true` is enabled at the system level, package environment building fails or shadows the alias. The standalone `vim` package must be removed from base system packages so `vim` and `vi` cleanly alias to `nvim`.
- **Automatic Symlink Creation When `~/.config` Does Not Yet Exist**: On a fresh or impermanent system where `/home/<user>/.config` may not exist for all paths prior to login, the system-level symlink mechanism must ensure parent directories exist with appropriate ownership or safely create/update `/home/<user>/.config/nvim` pointing to the declarative store path.
- **Store Path Updates Across System Generations**: When Neovim Lua configuration files are modified in the repository and a new system generation is activated, the `~/.config/nvim` symlink must automatically update (`L+` replacement semantics) to point to the new generation's store path rather than leaving a stale link.
- **Read-Only Configuration Directory with Writable Lockfile**: Because `~/.config/nvim` is a symlink into the read-only system store, the LazyVim configuration must continue writing `lazy-lock.json` to `~/.local/share/nvim/lazy-lock.json` so plugin updates succeed on both `desktop-pc` and `homelab`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a shared, system-level Neovim module (`core.neovim`) that can be enabled on any host (`desktop-pc`, `homelab`) without requiring Home Manager.
- **FR-002**: The shared Neovim module MUST enable Neovim at the system level with `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, and `withPython3 = true`.
- **FR-003**: The base system configuration (`core.base`) MUST NOT install the standalone `vim` package in `environment.systemPackages`, preventing binary collisions with the system-wide `vim` alias provided by `core.neovim`.
- **FR-004**: The shared Neovim module MUST declaratively link the LazyVim starter configuration directory (`init.lua`, `stylua.toml`, `lua/config/*`, `lua/plugins/*`) to `/home/<user>/.config/nvim` using system-level symlink management (`systemd.tmpfiles.rules` with `L+` semantics) so that the link is created and updated across system activations without Home Manager.
- **FR-005**: The shared Neovim module MUST provision all cross-platform LazyVim runtime dependencies at the system level (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`).
- **FR-006**: The desktop editors module (`desktop.editors`) MUST retain desktop-specific editor configurations (VS Code, Zed, and `wl-clipboard` for Wayland clipboard integration) and MUST remove its duplicate Home Manager Neovim configuration and dotfiles symlink.
- **FR-007**: Both `desktop-pc` and `homelab` host definitions MUST include the `core.neovim` feature module, and `homelab` MUST keep `enableHomeManager = false`.
- **FR-008**: The system preservation configuration (`core.preservation`) MUST persist the primary user's `.local/share/nvim` and `.local/state/nvim` directories on `/persistent` so LazyVim plugins, `lazy-lock.json`, compiled Tree-sitter parsers, undo history, and ShaDa state survive `homelab` reboots.
- **FR-009**: Project documentation (`README.md`) MUST be updated within the same branch to document the shared `core.neovim` module, its availability on both `desktop-pc` and `homelab`, and the persisted Neovim directories on `homelab`.

### Key Entities

- **Shared Neovim Feature Module (`core.neovim`)**: The system-level module encapsulating the Neovim program configuration, runtime CLI dependencies, and declarative `~/.config/nvim` symlink rule shared across desktop and server hosts.
- **Declarative LazyVim Dotfiles (`dotfiles/nvim`)**: The version-controlled Lua configuration files (`init.lua`, `stylua.toml`, `lua/config/*`, `lua/plugins/*`) colocated with the `core.neovim` module and linked into the user's XDG config directory.
- **Persisted Neovim User State (`.local/share/nvim`, `.local/state/nvim`)**: The user-owned directories preserved across reboots on impermanent hosts (`homelab`), storing cloned LazyVim plugins, `lazy-lock.json`, compiled Tree-sitter parsers, ShaDa files, and undo history.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Neovim configuration files (`init.lua`, `stylua.toml`, `lua/config/*`, `lua/plugins/*`) are maintained in a single shared location in the repository with 0 duplication between `desktop-pc` and `homelab`.
- **SC-002**: Both `desktop-pc` and `homelab` system configurations build and evaluate cleanly with 0 conflicts or errors, while `homelab` continues to evaluate with Home Manager disabled (`enableHomeManager = false`).
- **SC-003**: Invoking `nvim`, `vi`, or `vim` on either host launches the LazyVim configuration with 100% of required runtime CLI dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) present in the system `PATH`.
- **SC-004**: On `homelab`, 100% of installed LazyVim plugins, `lazy-lock.json`, compiled Tree-sitter parsers (`.local/share/nvim`), and editor state (`.local/state/nvim`) persist intact across host reboots without requiring plugin re-downloads.
- **SC-005**: 100% pass rate on all repository quality gates (`just fmt`, `just lint`, `just check`).

## Assumptions

- The primary user account managed on both `desktop-pc` and `homelab` is defined by `vars.userName` (`laurent`) with home directory `/home/${vars.userName}`.
- Moving the Neovim dotfiles directory alongside `modules/core/neovim.nix` (or referencing a single canonical path under `modules/core/`) is the cleanest way to colocate the shared feature's assets in accordance with the repository's Dendritic Pattern (Constitution Principle II).
- Terminal sessions connecting to `homelab` over SSH inherit Nerd Font rendering and true-color support from the client terminal emulator (such as WezTerm on `desktop-pc`), so no graphical font packages need to be installed on `homelab`.
