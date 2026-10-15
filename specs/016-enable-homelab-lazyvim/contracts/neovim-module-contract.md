# Interface Contract: Shared Core Neovim & Desktop Editors Modules

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](../spec.md)

This contract defines the module interfaces, attribute exports, and host composition rules for `modules/core/neovim.nix` and `modules/desktop/editors.nix`.

---

## 1. Core Neovim Module Interface (`modules/core/neovim.nix`)

`modules/core/neovim.nix` MUST export a dendritic Home Manager module at `flake.modules.core.neovim.homeManager`:

```nix
{
  flake.modules.core.neovim = {
    homeManager = {pkgs, ...}: {
      # Declarative LazyVim starter configuration symlink
      xdg.configFile."nvim".source = ./dotfiles/nvim;

      # Upstream LazyVim runtime dependencies
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

---

## 2. Desktop Editors Module Interface (`modules/desktop/editors.nix`)

`modules/desktop/editors.nix` MUST export `flake.modules.desktop.editors.homeManager` containing only desktop-specific editor tooling:

```nix
{
  flake.modules.desktop.editors = {
    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        # Wayland clipboard integration for Niri
        wl-clipboard
      ];

      programs = {
        vscode = {
          enable = true;
          # ... existing extensions and userSettings ...
        };

        zed-editor = {
          enable = true;
          # ... existing extensions and userSettings ...
        };
      };
    };
  };
}
```

---

## 3. Host Composition Contract

| Host | `core.neovim` | `desktop.editors` | Home Manager Active |
| --- | --- | --- | --- |
| `desktop-pc` (`modules/hosts/desktop-pc.nix`) | Enabled | Enabled | Yes |
| `homelab` (`modules/hosts/homelab.nix`) | Enabled | Disabled | Yes |
| `iso` (`modules/hosts/iso.nix`) | Disabled | Disabled | No |
