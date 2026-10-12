# Technical Research: Declarative LazyVim Configuration for NixOS

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and evaluated alternatives for implementing a declarative LazyVim setup on NixOS adhering to the dendritic pattern and upstream starter conventions.

---

## 1. Neovim Integration & Configuration Management

### Decision
Manage Neovim via Home Manager (`programs.neovim`) within `modules/desktop/editors.nix`. Remove the previous `nvf` NixOS configuration module.

```nix
# modules/desktop/editors.nix
{
  flake.modules.desktop.editors = {
    homeManager = {pkgs, ...}: {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
      };
      # ...
    };
  };
}
```

### Rationale
- **User-Centric Architecture**: In modern NixOS architectures, user-facing text editors, dotfiles, and development IDE configurations belong to user profile management (Home Manager). This aligns with `programs.vscode` and `programs.zed-editor` already present in `modules/desktop/editors.nix`.
- **Clean Deprecation of `nvf`**: The previous `nvf` NixOS module generated its own wrapper configuration, which is incompatible with LazyVim's Lua plugin manager layout (`lazy.nvim`). Removing `nvf` eliminates conflicting Neovim configurations.
- **Hermetic Aliases**: `programs.neovim` automatically creates `vi` and `vim` aliases pointing to the configured Neovim executable.

### Alternatives Considered
- **NixOS system-level module (`programs.neovim` in NixOS)**: Provides system-wide binaries, but user-level configuration (XDG config files, personal plugin extensions) is more naturally colocated with the desktop user session in Home Manager.
- **Nixvim (`github:nix-community/nixvim`)**: Replaces Neovim Lua configuration with Nix expressions. While declarative, it does not replicate the upstream `LazyVim/starter` Lua layout requested by the user and complicates porting community LazyVim snippets.
- **Keeping `nvf`**: Incompatible with LazyVim's native starter structure and dynamic plugin orchestration.

---

## 2. Upstream Getting Started Dependencies Provisioning

### Decision
Declare all runtime dependencies specified in LazyVim's upstream Getting Started guide (`https://www.lazyvim.org/installation`) within Home Manager's `home.packages` in `modules/desktop/editors.nix`.

```nix
home.packages = with pkgs; [
  # Core LazyVim dependencies
  git           # Plugin cloning and version control integration
  gcc           # C compiler for nvim-treesitter parser compilation
  gnumake       # Build tool for native extensions (e.g. fzf-native)
  ripgrep       # High-performance search for live grep and Telescope/Snacks
  fd            # Fast file finder for file discovery

  # Archive & utility tools
  curl
  unzip
  tar
  gzip

  # Wayland clipboard integration
  wl-clipboard
];
```

### Rationale
- **Strict Compliance with Upstream**: Upstream LazyVim explicitly mandates Neovim >= 0.9.0, Git >= 2.19.0, a C compiler (`gcc` or `clang`) for `nvim-treesitter`, `ripgrep`, and `fd`.
- **Path Resolution in NixOS**: NixOS does not have standard FHS paths like `/usr/bin/gcc` or `/usr/bin/rg`. Supplying them through `home.packages` guarantees they are present in the user's `$PATH` for Neovim's internal terminal subshells and `vim.fn.system` calls.
- **Wayland Clipboard Compatibility**: The target system runs the Niri Wayland compositor. Installing `wl-clipboard` ensures seamless clipboard synchronization with the system clipboard (`+` and `*` registers).
- **Native Extension Compilation**: `gnumake` and `gcc` allow `nvim-treesitter` to compile parsers into `~/.local/share/nvim` and build native fuzzy finding libraries without compilation failures.

### Alternatives Considered
- **Packaging all plugins purely via Nix (`pkgs.vimPlugins`)**: Disables LazyVim's native plugin manager (`lazy.nvim`), preventing standard LazyVim updates and breaking the `LazyVim/starter` workflow.
- **Relying on ambient system packages**: Violates Constitution Principle I (Hermeticity); missing dependencies on other hosts would break editor features.

---

## 3. Starter Configuration Replication & Read-Only Store Adaptation

### Decision
Store the exact `LazyVim/starter` file structure in `modules/desktop/dotfiles/nvim/` and link it to `~/.config/nvim` using `xdg.configFile."nvim".source = ./dotfiles/nvim;`.

```text
modules/desktop/dotfiles/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   └── plugins/
│       └── example.lua
└── stylua.toml
```

### Lockfile Adaptation for NixOS Read-Only Store
In standard LazyVim, `lazy.nvim` attempts to write `lazy-lock.json` directly into `vim.fn.stdpath("config") .. "/lazy-lock.json"`. Since `~/.config/nvim` is a symlink pointing to the read-only Nix store, write operations would fail with a read-only filesystem error during plugin installs and updates.

**Solution**: In `lua/config/lazy.lua`, configure `lockfile` in the `lazy.nvim` setup options:
```lua
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json", -- Write to ~/.local/share/nvim/lazy-lock.json
  defaults = {
    lazy = false,
    version = false,
  },
  -- ...
})
```

### Rationale
- **100% Starter Fidelity**: Replicates every file and module from `https://github.com/LazyVim/starter`.
- **Pure Declarative Version Control**: The base configuration files are managed in Git and deployed through Nix.
- **Graceful Mutability for Lockfile & Cache**: Redirecting the lockfile to `~/.local/share/nvim/` allows `lazy.nvim` to record updated commit hashes without mutating the Nix store or throwing permission errors.

### Alternatives Considered
- **Linking individual files (`init.lua`, `lua/`) to keep `~/.config/nvim` writable**: More verbose in Nix code; still leaves open the question of uncommitted local files in `~/.config/nvim`. Using `stdpath("data")` is cleaner and respects immutable configuration separation.

---

## 4. State Isolation & Ephemeral Root Compatibility

### Decision
Isolate all mutable plugin data, downloaded repositories, treesitter compiled grammars, and editor cache within:
- `~/.local/share/nvim` (plugin repositories, data, lockfile)
- `~/.cache/nvim` (parser cache, telemetry, temporary logs)
- `~/.local/state/nvim` (undo tree, view history, shada/registers)

Document these directories as transient runtime state in accordance with Constitution Principle I.

### Rationale
- Transient runtime state is automatically recreated or re-synced if wiped, ensuring clean separation between declarative configuration and runtime artifacts.
- Fits seamlessly with ephemeral root or state preservation schemes if configured.

---

## 5. Visual Styling & Font Integration

### Decision
Rely on the existing font definitions in `modules/desktop/fonts.nix` (`nerd-fonts.fira-code`) and terminal configuration in `modules/desktop/terminal.nix` (WezTerm with true-color and Catppuccin Mocha theme). Configure Tokyo Night (default LazyVim theme) and Habamax fallback in `lazy.lua`, with user ability to add Catppuccin in `lua/plugins/` if desired.

### Rationale
- Fulfills the Nerd Font (v3.0+) and 24-bit true-color requirements from LazyVim Getting Started without adding redundant font installations.
