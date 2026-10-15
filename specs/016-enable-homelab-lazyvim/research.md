# Technical Research: Enable Shared LazyVim Neovim Configuration on Homelab

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document consolidates technical research, architectural decisions, rationale, and evaluated alternatives for sharing the LazyVim-based Neovim configuration between `desktop-pc` and `homelab` within the repository's Dendritic Pattern architecture.

---

## 1. Dendritic Module Separation: Core Neovim vs. Desktop Graphical Editors

### Decision

Extract the LazyVim/Neovim configuration and its terminal runtime dependencies from `modules/desktop/editors.nix` into a dedicated core module `modules/core/neovim.nix` (`flake.modules.core.neovim`), and move the starter dotfiles directory from `modules/desktop/dotfiles/nvim/` to `modules/core/dotfiles/nvim/`. Retain `modules/desktop/editors.nix` (`flake.modules.desktop.editors`) for desktop-only graphical editors (`vscode`, `zed-editor`) and Wayland clipboard utilities (`wl-clipboard`).

```nix
# modules/core/neovim.nix
{
  flake.modules.core.neovim = {
    homeManager = {pkgs, ...}: {
      # Declarative LazyVim starter configuration symlink
      xdg.configFile."nvim".source = ./dotfiles/nvim;

      # Upstream LazyVim CLI runtime dependencies
      # Reference: https://www.lazyvim.org/installation
      home.packages = with pkgs; [
        # Upstream requirements
        git
        gcc
        gnumake
        ripgrep
        fd
        tree-sitter

        # Archive and download utilities
        curl
        unzip
        gnutar
        gzip
      ];

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
      };
    };
  };
}
```

### Rationale

- **Domain Alignment (Constitution Principle II)**: Under the repository's Dendritic Pattern, `modules/core/` holds foundational CLI and user-environment capabilities shared across workstation and server targets (matching `modules/core/git.nix`, which defines `flake.modules.core.git.homeManager`), whereas `modules/desktop/` encapsulates Wayland/GUI session tools (`niri`, `noctalia`, `wezterm`, `vscode`, `zed-editor`).
- **Zero GUI Bloat on Homelab**: Separating `core.neovim` from `desktop.editors` guarantees that enabling `core.neovim` on `homelab` never pulls `vscode`, `zed-editor`, or Wayland-specific packages into the headless server closure.
- **Single Source of Truth**: Moving `dotfiles/nvim` to `modules/core/dotfiles/nvim` ensures both `desktop-pc` and `homelab` reference the exact same Lua files with zero duplication.

### Alternatives Considered

- **Importing `desktop.editors` directly on `homelab`**: Rejected because `desktop.editors` enables `programs.vscode` and `programs.zed-editor`, which would install gigabytes of graphical IDE dependencies and X11/Wayland libraries on the headless `homelab` server.
- **Duplicating `dotfiles/nvim` and `programs.neovim` in `homelab.nix` extraModules**: Rejected because it violates Constitution Principle II (no inline service/feature definitions in host files) and creates configuration drift between `desktop-pc` and `homelab`.

---

## 2. Enabling Home Manager on `homelab`

### Decision

Remove `enableHomeManager = false;` from `modules/hosts/homelab.nix` and include `core.neovim` in `homelab`'s `features` list alongside `core.base` and `core.preservation`.

### Rationale

- **Automatic Detection in `mkHost`**: In `modules/core/lib.nix`, `hasHomeManager` defaults to `(homeManagerModules != [])` when `enableHomeManager` is not forced to `false`.
- **Consistent User Profile Management**: `core.base` already defines the baseline `homeManager` block (`home.username = vars.userName`, `home.homeDirectory = "/home/${vars.userName}"`, `home.stateVersion = "26.05"`, `systemd.user.startServices = "sd-switch"`). Enabling Home Manager on `homelab` allows `core.neovim` (and `services.ssh`'s `homeManager` block) to declaratively provision `~/.config/nvim` and user packages (`useGlobalPkgs = true`, `useUserPackages = true`) using the exact same mechanism as `desktop-pc`.
- **Compatibility with `users.users.<name>.packages`**: In `modules/hosts/homelab.nix`, `users.users.${config.flake.vars.userName}.packages = with pkgs; [ tree ];` merges cleanly with Home Manager's `useUserPackages = true` via the NixOS module system list merge.

### Alternatives Considered

- **Rewriting LazyVim to use NixOS-level `/etc/xdg/nvim` instead of Home Manager**: Rejected because `desktop-pc` manages LazyVim via Home Manager (`xdg.configFile."nvim"` and `programs.neovim`); using two different mechanisms across hosts would introduce divergence and complicate user-scoped dotfiles management.

---

## 3. State Preservation on the Impermanent `homelab` Server

### Decision

Register `.local/share/nvim` and `.local/state/nvim` under `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/core/preservation.nix`.

```nix
# modules/core/preservation.nix
users.${vars.userName} = {
  directories = [
    ".ssh"
    ".config/gh" # GitHub CLI authentication and configuration
    ".local/share/fish" # Fish shell history and universal variables
    ".local/share/nvim" # LazyVim plugins, lockfile, and Tree-sitter parsers
    ".local/state/nvim" # Neovim undo history, ShaDa, and session state
  ];
};
```

### Rationale

- **Surviving Ephemeral Reboots**: `homelab` mounts `/` on `tmpfs` in RAM. Without preserving `~/.local/share/nvim` and `~/.local/state/nvim`, every reboot would delete cloned `lazy.nvim` plugins, `lazy-lock.json`, compiled Tree-sitter `.so` parsers, ShaDa history, and undo trees.
- **Clean Separation from Immutable Config**: `~/.config/nvim` is NOT added to `preservation` because it is a read-only symlink into `/nix/store` recreated on every boot by Home Manager activation.
- **Matches Existing Pattern**: Follows the exact convention already used in `modules/core/preservation.nix` for `.local/share/fish` and `.config/gh` (and replaces the commented-out `# ".local/state/neovim"` placeholder).

### Alternatives Considered

- **Persisting `~/.cache/nvim`**: Unnecessary; transient cache files in `~/.cache/nvim` are lightweight and safely regenerated by Neovim on demand without network downloads.
- **Not persisting `~/.local/share/nvim`**: Would force LazyVim to re-clone ~40 Git repositories and recompile C parsers after every server reboot, degrading startup time and failing if rebooted without internet access.

---

## 4. Headless Clipboard & Terminal Behavior Over SSH

### Decision

Keep `pkgs.wl-clipboard` in `modules/desktop/editors.nix` (for the Niri Wayland session on `desktop-pc`) while omitting `wl-clipboard` from `modules/core/neovim.nix`.

### Rationale

- **Built-in OSC 52 Support in Neovim >= 0.10**: Modern Neovim automatically uses the terminal's OSC 52 clipboard provider over SSH sessions (supported out of the box by WezTerm on `desktop-pc`), allowing copy/paste between remote `homelab` Neovim sessions and the local desktop clipboard without requiring X11/Wayland daemons on `homelab`.
- **Desktop Wayland Support Preserved**: `desktop-pc` still includes `desktop.editors`, which provides `wl-clipboard` for local Wayland clipboard integration under Niri.
