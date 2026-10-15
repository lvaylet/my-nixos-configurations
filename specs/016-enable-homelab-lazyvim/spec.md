# Feature Specification: Enable Shared LazyVim Neovim Configuration on Homelab

**Feature Branch**: `016-enable-homelab-lazyvim`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Fais en sorte que la configuration Neovim de `desktop-pc` basée sur LazyVim soit également disponible sur `homelab`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified LazyVim Editing Environment on Homelab (Priority: P1)

As a system administrator and developer connecting to `homelab` over SSH or a local terminal, I want to launch the editor (`nvim`, `vi`, or `vim`) and immediately access the exact same LazyVim-based Neovim configuration and CLI runtime dependencies as on `desktop-pc`, so that I can navigate, search, and edit files on the server with a consistent modal editing experience.

**Why this priority**: Directly delivers the requested user capability—making the `desktop-pc` LazyVim Neovim environment available and fully functional on `homelab`.

**Independent Test**: Can be fully tested by building/activating the `homelab` configuration, opening a shell session as the primary user (`laurent`), running `nvim` (or `vi` / `vim`), and verifying that the LazyVim starter dashboard, keybindings, fuzzy file finder (`fd`), live grep (`ripgrep`), and Tree-sitter compilation toolchain (`gcc`, `make`, `tree-sitter`) work without missing-binary errors.

**Acceptance Scenarios**:

1. **Given** an active user session on `homelab`, **When** the user runs `nvim`, `vi`, or `vim`, **Then** Neovim launches with the shared LazyVim starter configuration, theme, statusline, and keybindings identical to `desktop-pc`.
2. **Given** an open workspace in Neovim on `homelab`, **When** the user triggers file finding, live text search, or syntax parser compilation, **Then** all required CLI runtime dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) are present in the user's environment and execute without errors.
3. **Given** an interactive shell session on `homelab`, **When** a command or tool invokes the default system/user editor (`$EDITOR`), **Then** the declarative Neovim instance is launched by default.

---

### User Story 2 - Single Source of Truth Without Desktop GUI Bloat (Priority: P1)

As a repository maintainer, I want the LazyVim configuration and its CLI dependencies to be shared between `desktop-pc` and `homelab` from a single declarative module and dotfiles source—without installing graphical desktop editors (VS Code, Zed) or Wayland-only desktop applications on `homelab`—so that updates to the Neovim configuration automatically apply to both hosts while keeping `homelab` headless and minimal.

**Why this priority**: Prevents configuration drift between `desktop-pc` and `homelab` and ensures the headless server closure is not polluted with heavyweight graphical desktop packages.

**Independent Test**: Can be tested by inspecting the repository module hierarchy to confirm a single `nvim` dotfiles directory exists, evaluating both `desktop-pc` and `homelab` system closures, and verifying that `homelab` includes the LazyVim configuration while excluding `vscode` and `zed-editor`.

**Acceptance Scenarios**:

1. **Given** the repository's module structure, **When** a maintainer modifies a Lua file in the LazyVim dotfiles directory, **Then** both `desktop-pc` and `homelab` inherit the updated Neovim configuration on rebuild without duplicating files.
2. **Given** the `homelab` host configuration closure, **When** the system derivation is evaluated, **Then** graphical desktop editors (`vscode`, `zed-editor`) are not installed in the `homelab` user or system profile.
3. **Given** the `desktop-pc` host configuration closure, **When** the system derivation is evaluated, **Then** both the shared LazyVim Neovim setup and the graphical desktop editors (`vscode`, `zed-editor`) remain enabled and unchanged in behavior.

---

### User Story 3 - Persistent Editor State Across Impermanent Homelab Reboots (Priority: P2)

As a system administrator operating the impermanent (`tmpfs` root) `homelab` server, I want Neovim's downloaded LazyVim plugins, plugin lockfile, compiled Tree-sitter parsers, and editor state (undo history, ShaDa, state files) to persist across reboots under `/persistent`, so that Neovim starts immediately after a server reboot without re-downloading plugins or losing editing history.

**Why this priority**: `homelab` uses an ephemeral root filesystem with explicit state preservation; without persisting Neovim's data and state directories, every reboot would wipe installed plugins and trigger a full bootstrap download on next launch.

**Independent Test**: Can be tested by verifying that the preservation configuration declares the user's Neovim data and state directories (`.local/share/nvim` and `.local/state/nvim`) for persistence under `/persistent`.

**Acceptance Scenarios**:

1. **Given** `homelab` with LazyVim plugins initialized in `~/.local/share/nvim` and editor state in `~/.local/state/nvim`, **When** the `homelab` host reboots, **Then** all downloaded plugins, compiled Tree-sitter grammars, `lazy-lock.json`, and editor state files remain intact.
2. **Given** the declarative LazyVim configuration in `~/.config/nvim`, **When** `homelab` boots or switches generations, **Then** `~/.config/nvim` is provisioned declaratively from the Nix store without manual intervention.

---

### User Story 4 - Repository Quality Gates and Documentation Synchronization (Priority: P2)

As a contributor, I want all module changes and host compositions to adhere to the Dendritic Pattern, pass all repository quality checks, and keep `README.md` synchronized with the updated module architecture, so that the repository remains compliant with its governance constitution.

**Why this priority**: Ensures compliance with project Constitution Principles II, III, V, and VI.

**Independent Test**: Run `just fmt`, `just lint`, and `just check` and verify exit code 0 alongside updated architecture descriptions in `README.md`.

**Acceptance Scenarios**:

1. **Given** the updated Nix modules and host definitions, **When** `just fmt`, `just lint`, and `just check` are executed, **Then** all formatting, static analysis, and flake evaluation checks pass with zero errors or warnings.
2. **Given** `README.md`, **When** inspecting the architecture and module documentation, **Then** any changes to module organization or host capabilities are accurately reflected.

---

### Edge Cases

- **Headless Terminal Environment over SSH**: When connecting to `homelab` over SSH without a local Wayland compositor, Neovim must operate cleanly in terminal mode without failing due to absent graphical display servers; terminal-based clipboard integration (such as OSC 52 over SSH) works automatically in modern Neovim while Wayland clipboard utilities remain available on desktop sessions.
- **Impermanent Root Filesystem on Homelab**: Because `homelab` wipes `/` on reboot, `~/.config/nvim` must be recreated declaratively by Home Manager on activation, while mutable plugin and state directories (`~/.local/share/nvim`, `~/.local/state/nvim`) must be persisted via `core.preservation` so plugins are not lost across reboots.
- **Conflicting System-Wide Editor Packages**: If `core.base` installs a basic `vim` package in `environment.systemPackages`, the user profile's `vi` and `vim` aliases and `EDITOR` environment variable must cleanly resolve to the declarative LazyVim Neovim instance without package collisions.
- **First Launch Without Cached Plugins**: On initial deployment before plugins are cached in `/persistent`, launching `nvim` on `homelab` with network connectivity automatically bootstraps `lazy.nvim` and installs the starter plugins into `~/.local/share/nvim` using the writable lockfile path (`~/.local/share/nvim/lazy-lock.json`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST make the declarative LazyVim Neovim configuration (`init.lua`, `stylua.toml`, `lua/config/*`, `lua/plugins/*`) available to the primary user (`vars.userName`) on both `desktop-pc` and `homelab` from a single shared source directory.
- **FR-002**: The system MUST configure Neovim on `homelab` with the same program settings as `desktop-pc`, including enabling Neovim, setting it as the default editor (`defaultEditor = true`), enabling `vi` and `vim` aliases (`viAlias = true`, `vimAlias = true`), and enabling Node.js and Python 3 providers (`withNodeJs = true`, `withPython3 = true`).
- **FR-003**: The system MUST install all required LazyVim CLI runtime dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) on both `desktop-pc` and `homelab`.
- **FR-004**: The system MUST NOT install graphical desktop editors (`vscode`, `zed-editor`) on `homelab`, keeping those graphical editors scoped strictly to `desktop-pc`.
- **FR-005**: The system MUST enable Home Manager user environment management for `vars.userName` on `homelab` so that declarative user-level configurations (including `~/.config/nvim` and `programs.neovim`) are provisioned consistently across `desktop-pc` and `homelab`.
- **FR-006**: The system MUST persist the primary user's Neovim runtime data and state directories (`.local/share/nvim` and `.local/state/nvim`) in `modules/core/preservation.nix` so downloaded LazyVim plugins, compiled Tree-sitter parsers, lockfiles, and editing history survive reboots on impermanent hosts (`homelab`).
- **FR-007**: The module organization MUST adhere to the repository's Dendritic Pattern (`import-tree ./modules`), with host files (`modules/hosts/desktop-pc.nix` and `modules/hosts/homelab.nix`) composing features declaratively without inline service or dotfile duplication.
- **FR-008**: `README.md` MUST be updated if module responsibilities or host feature descriptions change, maintaining compliance with Constitution Principle VI.

### Key Entities

- **Shared Neovim / LazyVim Feature Module**: The declarative feature module providing the Neovim package, aliases, CLI runtime dependencies, and `~/.config/nvim` dotfile link for any host that includes it.
- **LazyVim Dotfiles Bundle**: The single shared directory of Lua configuration files (`init.lua`, `stylua.toml`, `lua/config/*`, `lua/plugins/*`) linked to `~/.config/nvim` on both `desktop-pc` and `homelab`.
- **Desktop Graphical Editors Module**: The desktop-scoped feature module providing GUI code editors (`vscode`, `zed-editor`) and Wayland clipboard utilities exclusively for graphical workstation hosts (`desktop-pc`).
- **Preserved User Neovim State**: The persistent directories (`.local/share/nvim`, `.local/state/nvim`) stored on `/persistent` on `homelab` to retain LazyVim plugins, lockfiles, Tree-sitter parsers, and editor state across ephemeral reboots.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of LazyVim starter configuration files (`init.lua`, `stylua.toml`, `lua/config/autocmds.lua`, `lua/config/keymaps.lua`, `lua/config/lazy.lua`, `lua/config/options.lua`, `lua/plugins/example.lua`) are shared from a single repository path and linked identically into `~/.config/nvim` on both `desktop-pc` and `homelab`.
- **SC-002**: 100% of required LazyVim CLI runtime dependencies (`nvim`, `git`, `gcc`, `make`, `rg`, `fd`, `tree-sitter`, `curl`, `unzip`, `tar`, `gzip`) are available in the user environment on both `desktop-pc` and `homelab`.
- **SC-003**: 0 graphical desktop editor packages (`vscode`, `zed-editor`) are present in the evaluated `homelab` system closure.
- **SC-004**: 100% of existing editor capabilities on `desktop-pc` (LazyVim, VS Code, Zed, `wl-clipboard`) remain present and functional without regression.
- **SC-005**: 100% of Neovim user plugin and state directories (`.local/share/nvim`, `.local/state/nvim`) are registered for persistence across reboots on `homelab`.
- **SC-006**: 100% pass rate on repository formatting, static analysis, and flake checks (`just fmt`, `just lint`, `just check`) across all host configurations (`desktop-pc`, `homelab`, `iso`).

## Assumptions

- `homelab` is accessed primarily as the user defined in `config.flake.vars.userName` (`laurent`), matching the user account managed by Home Manager on `desktop-pc`.
- Enabling Home Manager on `homelab` with `core.base` and the shared Neovim feature module is the cleanest declarative mechanism to share user-scoped `programs.neovim` and `xdg.configFile."nvim"` configurations identically between `desktop-pc` and `homelab`.
- Transient cache files in `~/.cache/nvim` do not require persistence across reboots on `homelab` as they are safely regenerated on demand, whereas `~/.local/share/nvim` (plugins, grammars, lockfile) and `~/.local/state/nvim` (undo history, ShaDa) benefit from persistence under `/persistent`.
