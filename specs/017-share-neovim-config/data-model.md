# Data Model: Shared System-Level Neovim Configuration

**Branch**: `017-share-neovim-config` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

---

## Entities & Configuration Schema

### Entity 1: Shared Neovim Feature Module (`modules/core/neovim.nix`)

| Component | Option Path | Value / Type | Purpose |
|---|---|---|---|
| **Dendritic Capability** | `flake.modules.core.neovim.nixos` | Function (`{pkgs, vars, ...}: { ... }`) | System-level NixOS module shared across `desktop-pc` and `homelab` |
| **Neovim Engine** | `programs.neovim.enable` | `true` (boolean) | Installs Neovim system-wide |
| | `programs.neovim.defaultEditor` | `true` (boolean) | Exports `EDITOR=nvim` globally |
| | `programs.neovim.viAlias` | `true` (boolean) | Symlinks `vi` to `nvim` |
| | `programs.neovim.vimAlias` | `true` (boolean) | Symlinks `vim` to `nvim` |
| | `programs.neovim.withNodeJs` | `true` (boolean) | Enables Node.js remote plugin provider |
| | `programs.neovim.withPython3` | `true` (boolean) | Enables Python 3 remote plugin provider |
| **Runtime Packages** | `environment.systemPackages` | List of packages (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) | Provides all CLI tools mandated by LazyVim |
| **Config Symlink** | `systemd.tmpfiles.rules` | `["d /home/${vars.userName}/.config 0755 ${vars.userName} users -" "L+ /home/${vars.userName}/.config/nvim - - - - ${./dotfiles/nvim}"]` | Declaratively creates and updates `~/.config/nvim` symlink to Nix store |

---

### Entity 2: Relocated LazyVim Starter Dotfiles (`modules/core/dotfiles/nvim/`)

```text
modules/core/dotfiles/nvim/
├── init.lua                  # Entrypoint: require("config.lazy")
├── stylua.toml               # Lua formatting rules
└── lua/
    ├── config/
    │   ├── autocmds.lua      # Autocommands loaded on VeryLazy
    │   ├── keymaps.lua       # Keymaps loaded on VeryLazy
    │   ├── lazy.lua          # lazy.nvim bootstrap + lockfile in stdpath("data")
    │   └── options.lua       # Options loaded before lazy.nvim
    └── plugins/
        └── example.lua       # Example user plugin specifications
```

---

### Entity 3: Persisted User State on `homelab` (`modules/core/preservation.nix`)

| Relative User Path (`~`) | Backing Path on `homelab` | Contents | Lifecycle |
|---|---|---|---|
| `.local/share/nvim` | `/persistent/home/${vars.userName}/.local/share/nvim` | `lazy/` plugin clones, `lazy-lock.json`, `treesitter/` parsers | Created on first `nvim` launch; preserved across reboots |
| `.local/state/nvim` | `/persistent/home/${vars.userName}/.local/state/nvim` | `shada/main.shada`, undo files, swap/session state | Updated during editing sessions; preserved across reboots |

---

## Validation Rules

1. **Zero Binary Conflict**: `pkgs.vim` MUST NOT be present alongside `programs.neovim.vimAlias = true` in `environment.systemPackages`.
2. **Home Manager Independence on `homelab`**: `nixosConfigurations.homelab.config` MUST evaluate with `enableHomeManager = false` while containing `programs.neovim.enable == true`.
3. **Store Symlink Integrity**: `systemd.tmpfiles.rules` on both `desktop-pc` and `homelab` MUST contain the `L+ /home/laurent/.config/nvim` rule pointing to the store derivation of `modules/core/dotfiles/nvim`.
4. **Impermanence Coverage**: `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".users.laurent.directories` MUST include both `.local/share/nvim` and `.local/state/nvim`.
