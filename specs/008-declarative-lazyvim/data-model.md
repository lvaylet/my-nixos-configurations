# Data Model: Declarative LazyVim Configuration for NixOS

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, file hierarchy structures, and invariant validation rules for the declarative LazyVim setup on NixOS.

---

## 1. Entities & Configuration Schemas

### Entity 1: Desktop Editors Feature Module (`modules/desktop/editors.nix`)

Represents the dendritic feature module managing text editors (Neovim/LazyVim, VS Code, Zed) within the user's desktop environment via Home Manager.

| Category | Option / Attribute | Type / Value | Purpose |
|---|---|---|---|
| **Dendritic Identification** | `flake.modules.desktop.editors.homeManager` | Home Manager module function | Exported module definition discovered via `import-tree` |
| **Neovim Engine** | `programs.neovim.enable` | `true` (boolean) | Activates Neovim package and environment |
| | `programs.neovim.defaultEditor` | `true` (boolean) | Sets `$EDITOR` and `$VISUAL` environment variables to `nvim` |
| | `programs.neovim.viAlias` | `true` (boolean) | Aliases `vi` command to `nvim` |
| | `programs.neovim.vimAlias` | `true` (boolean) | Aliases `vim` command to `nvim` |
| | `programs.neovim.withNodeJs` | `true` (boolean) | Provides Node.js provider for LSP servers requiring Node |
| | `programs.neovim.withPython3` | `true` (boolean) | Provides Python 3 provider for Python plugins |
| **XDG Configuration** | `xdg.configFile."nvim".source` | `./dotfiles/nvim` (path) | Symlinks the declarative starter files into `~/.config/nvim` |
| **Runtime Dependencies** | `home.packages` | Package list | Provides CLI tools required by LazyVim Getting Started |
| | `pkgs.git` | Package | Upstream requirement: Git >= 2.19.0 for plugin cloning |
| | `pkgs.gcc` | Package | Upstream requirement: C compiler for Tree-sitter parsers |
| | `pkgs.gnumake` | Package | Build tool for native extensions (e.g. fzf-native) |
| | `pkgs.ripgrep` | Package | Upstream requirement: Live grep / Telescope pattern search |
| | `pkgs.fd` | Package | Upstream requirement: Fast file discovery |
| | `pkgs.wl-clipboard` | Package | Wayland clipboard integration for Niri compositor |
| | `pkgs.curl`, `pkgs.unzip`, `pkgs.tar`, `pkgs.gzip` | Packages | Archiving utilities for downloading and unpacking plugins |

#### Relationships

- **Composed into**: `modules/hosts/desktop-pc.nix` via `config.flake.modules.desktop.editors`.
- **References**: `modules/desktop/dotfiles/nvim` as source for `xdg.configFile."nvim"`.
- **Replaces**: Legacy `nvf` NixOS module (`programs.nvf`) previously defined in `modules/desktop/editors.nix`.
- **Complements**: `modules/desktop/fonts.nix` (providing Nerd Fonts) and `modules/desktop/terminal.nix` (WezTerm terminal).

---

### Entity 2: Starter Configuration File Layout (`modules/desktop/dotfiles/nvim/`)

Represents the declarative file hierarchy mirroring `https://github.com/LazyVim/starter`.

```text
modules/desktop/dotfiles/nvim/
├── init.lua                     # Entrypoint bootstrapping require("config.lazy")
├── stylua.toml                  # Lua formatting configuration
└── lua/
    ├── config/
    │   ├── autocmds.lua         # Autocmds loaded on VeryLazy event
    │   ├── keymaps.lua          # Keymaps loaded on VeryLazy event
    │   ├── lazy.lua             # Plugin manager setup & lockfile configuration
    │   └── options.lua          # Baseline editor options loaded before startup
    └── plugins/
        └── example.lua          # Example extension file demonstrating user plugin overrides
```

#### Attribute Specification per Configuration File

| File | Upstream Role | NixOS Specific Adaptation |
|---|---|---|
| `init.lua` | Root entrypoint | None (standard `require("config.lazy")`) |
| `lua/config/lazy.lua` | Lazy.nvim initialization, plugin specs, and plugin manager settings | Set `lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"` to keep lockfile in writable storage |
| `lua/config/options.lua` | Global options (`vim.g`, `vim.opt`) | None (upstream starter defaults) |
| `lua/config/keymaps.lua` | Global keybindings | None (upstream starter defaults) |
| `lua/config/autocmds.lua` | Global autocommands | None (upstream starter defaults) |
| `lua/plugins/example.lua` | User plugin examples | None (upstream starter examples) |
| `stylua.toml` | StyLua code formatting rules | None (upstream starter defaults) |

---

### Entity 3: Runtime Dependency Bundle

Represents the set of external binaries required for the editor to execute correctly without missing-tool errors.

| Dependency | Minimum Version | Upstream Rationale | Verification Command |
|---|---|---|---|
| `neovim` | >= 0.9.0 | Core editor runtime with LuaJIT | `nvim --version` |
| `git` | >= 2.19.0 | Plugin cloning, updates, and Git status | `git --version` |
| `gcc` | >= 12.0 | C compiler for compiling Tree-sitter parsers | `gcc --version` |
| `ripgrep` | >= 13.0 | Regex search inside files for Telescope / Snacks | `rg --version` |
| `fd` | >= 8.0 | File indexing and path search | `fd --version` |
| `wl-clipboard` | Latest | Wayland clipboard integration (`wl-copy`, `wl-paste`) | `wl-copy --version` |

---

### Entity 4: Transient State Store

Represents mutable runtime data created dynamically during editor usage. Stored outside the declarative repository and outside the read-only Nix store.

| Path | Purpose | Lifecycle / Persistence |
|---|---|---|
| `~/.local/share/nvim/lazy/` | Cloned Git repositories for LazyVim plugins | Created upon initial launch; persistent across sessions |
| `~/.local/share/nvim/lazy-lock.json` | Exact Git commit pins for installed plugins | Updated when running `:Lazy update` or `:Lazy sync` |
| `~/.local/share/nvim/treesitter/` | Compiled shared objects (`.so`) for Tree-sitter language parsers | Generated on demand by `nvim-treesitter` |
| `~/.cache/nvim/` | Transient cache files, log files, and indexing artifacts | Recreatable; safe to clear |
| `~/.local/state/nvim/` | Undo history files, view files, and ShaDa register persistence | Preserved across sessions for editing convenience |

---

## 2. Invariants & Validation Constraints

1. **Declarative Hermeticity (Constitution Principle I)**:
   - All files in `~/.config/nvim` MUST originate from the declarative Nix store symlink.
   - The declarative repository MUST NOT contain imperative local state or hardcoded absolute user home paths.
2. **Writable Lockfile Invariant**:
   - The lockfile path MUST be explicitly directed to `stdpath("data")` (`~/.local/share/nvim/lazy-lock.json`) so that `lazy.nvim` plugin updates never attempt to write to the read-only Nix store in `~/.config/nvim`.
3. **Dendritic Modularity (Constitution Principle II)**:
   - `modules/desktop/editors.nix` MUST be auto-discovered by `import-tree ./modules` and evaluated by `flake-parts`.
   - `modules/hosts/desktop-pc.nix` MUST NOT contain inline editor configuration; it only references `desktop.editors`.
4. **Clean Code & Formatting (Constitution Principle III)**:
   - `modules/desktop/editors.nix` MUST format cleanly with `alejandra` and pass `deadnix` and `statix check`.
5. **No Regressions on System Builds**:
   - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` MUST succeed with zero evaluation errors.
