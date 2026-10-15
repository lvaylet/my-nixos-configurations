# Data Model: Enable Shared LazyVim Neovim Configuration on Homelab

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, module boundaries, configuration attributes, and validation invariants for sharing the LazyVim Neovim configuration across `desktop-pc` and `homelab`.

---

## 1. Entities & Configuration Schemas

### Entity 1: Core Neovim Feature Module (`modules/core/neovim.nix`)

Represents the shared dendritic feature module providing the declarative LazyVim Neovim environment and CLI runtime toolchain to any host that enables `core.neovim`.

| Category | Option / Attribute | Type / Value | Purpose |
| --- | --- | --- | --- |
| **Dendritic Export** | `flake.modules.core.neovim.homeManager` | Home Manager module function | Auto-discovered via `import-tree ./modules` |
| **XDG Configuration** | `xdg.configFile."nvim".source` | `./dotfiles/nvim` (path) | Symlinks the shared LazyVim starter files into `~/.config/nvim` |
| **Neovim Program** | `programs.neovim.enable` | `true` (boolean) | Installs Neovim and generates user wrapper |
| | `programs.neovim.defaultEditor` | `true` (boolean) | Sets `EDITOR=nvim` in user session |
| | `programs.neovim.viAlias` | `true` (boolean) | Creates `vi` alias/symlink to `nvim` |
| | `programs.neovim.vimAlias` | `true` (boolean) | Creates `vim` alias/symlink to `nvim` |
| | `programs.neovim.withNodeJs` | `true` (boolean) | Enables Node.js provider for LSPs/plugins |
| | `programs.neovim.withPython3` | `true` (boolean) | Enables Python 3 provider for plugins |
| **CLI Runtime Dependencies** | `home.packages` | List of packages | `git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip` |

#### Relationships

- **Composed into**: `modules/hosts/desktop-pc.nix` and `modules/hosts/homelab.nix` via `config.flake.modules.core.neovim`.
- **References**: `modules/core/dotfiles/nvim` as the single source of truth for LazyVim starter files.
- **Complemented by**: `modules/core/preservation.nix` on `homelab` (persisting runtime plugin and state directories) and `modules/desktop/editors.nix` on `desktop-pc` (adding GUI editors and `wl-clipboard`).

---

### Entity 2: Shared LazyVim Dotfiles Bundle (`modules/core/dotfiles/nvim/`)

Represents the immutable starter Lua configuration shared across hosts.

```text
modules/core/dotfiles/nvim/
├── init.lua                     # Entrypoint bootstrapping require("config.lazy")
├── stylua.toml                  # Lua formatting configuration
└── lua/
    ├── config/
    │   ├── autocmds.lua         # Autocmds loaded on VeryLazy event
    │   ├── keymaps.lua          # Keymaps loaded on VeryLazy event
    │   ├── lazy.lua             # Plugin manager setup & writable lockfile path
    │   └── options.lua          # Baseline editor options loaded before startup
    └── plugins/
        └── example.lua          # Starter example plugin specification
```

---

### Entity 3: Desktop Graphical Editors Module (`modules/desktop/editors.nix`)

Represents the desktop-only editor module retained exclusively for graphical workstation hosts (`desktop-pc`).

| Category | Option / Attribute | Type / Value | Purpose |
| --- | --- | --- | --- |
| **Dendritic Export** | `flake.modules.desktop.editors.homeManager` | Home Manager module function | Auto-discovered via `import-tree ./modules` |
| **Wayland Clipboard** | `home.packages` | `[ pkgs.wl-clipboard ]` | Wayland clipboard utility for Niri desktop session |
| **VS Code** | `programs.vscode` | Attribute set (`enable = true`, extensions, `userSettings`) | Declarative Visual Studio Code IDE configuration |
| **Zed Editor** | `programs.zed-editor` | Attribute set (`enable = true`, extensions, `userSettings`) | Declarative Zed IDE configuration |

#### Relationships

- **Composed into**: `modules/hosts/desktop-pc.nix` only (`NOT` included in `modules/hosts/homelab.nix`).

---

### Entity 4: Preserved User Neovim State (`modules/core/preservation.nix`)

Represents the persistent user directories mapped to `/persistent/home/${vars.userName}/` on impermanent hosts (`homelab`).

| User Relative Path | Persistent Backing Path | Contents |
| --- | --- | --- |
| `.local/share/nvim` | `/persistent/home/laurent/.local/share/nvim` | Cloned `lazy.nvim` plugins, `lazy-lock.json`, compiled Tree-sitter parsers, Mason packages |
| `.local/state/nvim` | `/persistent/home/laurent/.local/state/nvim` | Undo history, ShaDa file, swap files, session state |

---

## 2. Validation Rules & Invariants

1. **Single Dotfiles Source Invariant**:
   - `modules/core/dotfiles/nvim/` MUST be the only `nvim` dotfiles directory in the repository (`modules/desktop/dotfiles/nvim/` MUST be removed after migration).
2. **Host Composition Invariant**:
   - `modules/hosts/desktop-pc.nix` MUST include both `core.neovim` and `desktop.editors`.
   - `modules/hosts/homelab.nix` MUST include `core.neovim` (with Home Manager enabled) and MUST NOT include `desktop.editors`.
3. **Headless Closure Purity Invariant**:
   - Evaluating `homelab`'s user packages MUST include `neovim` and all LazyVim CLI dependencies and MUST NOT include `vscode` or `zed-editor`.
4. **Impermanence Persistence Invariant**:
   - `modules/core/preservation.nix` MUST include `.local/share/nvim` and `.local/state/nvim` in `preservation.preserveAt."/persistent".users.${vars.userName}.directories`.
