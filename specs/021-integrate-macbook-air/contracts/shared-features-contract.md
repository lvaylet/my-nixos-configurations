# Shared Features & Portability Contract

**Feature**: `021-integrate-macbook-air`
**Contract Version**: 1.0.0
**Scope**: Cross-platform feature structure and conditional resource guarding

---

## 1. Feature Module Structure

Every dendritic feature under `modules/` MUST structure multi-platform capabilities using one or more of the following standard top-level keys:

```nix
{
  flake.modules.<domain>.<feature> = {
    # System-level NixOS declarations (Linux only)
    nixos = { pkgs, config, vars, ... }: { ... };

    # System-level nix-darwin declarations (macOS only)
    darwin = { pkgs, config, vars, ... }: { ... };

    # Cross-platform Home Manager declarations (Linux & macOS)
    homeManager = { pkgs, config, vars, ... }: { ... };
  };
}
```

---

## 2. Platform Guarding Rules in Shared Home Manager Modules

When a Home Manager module includes capabilities that differ between Linux and Darwin, the following rules apply:

### 2.1 Clipboard Utilities (`modules/desktop/editors.nix`)

- **Linux**: Installs `wl-clipboard` for Wayland clipboard support.
- **Darwin**: `wl-clipboard` MUST NOT be installed (macOS provides native `pbcopy`/`pbpaste`).
- **Guarding Pattern**:

  ```nix
  home.packages = with pkgs; [ ... ] ++ lib.optionals pkgs.stdenv.isLinux [ wl-clipboard ];
  ```

### 2.2 Terminal Compositor Settings (`modules/desktop/terminal.nix`)

- **Linux**: Sets `config.enable_wayland = true` in WezTerm.
- **Darwin**: `enable_wayland` is omitted or false.
- **Guarding Pattern**: Use Lua conditional or Nix string interpolation checking `pkgs.stdenv.isLinux`.

### 2.3 Font Discovery & Config (`modules/desktop/fonts.nix`)

- **Linux**: Enables `fonts.fontconfig.enable = true` and sets default monospace fonts.
- **Darwin**: Fonts are deployed to macOS user fonts directory; `fonts.fontconfig` MUST be gated by `pkgs.stdenv.isLinux`.

### 2.4 Partitioning & Disk Utilities (`modules/desktop/apps.nix`)

- **Linux**: Installs `efibootmgr`, `gptfdisk`, `parted`, `tparted`.
- **Darwin**: Disk utilities MUST NOT be installed on Darwin (macOS uses native APFS tools).
- **Guarding Pattern**:

  ```nix
  (lib.optionals pkgs.stdenv.isLinux [
    efibootmgr
    gptfdisk
    parted
    tparted
  ])
  ```

### 2.5 Neovim Dotfile Symlinking (`modules/core/neovim.nix`)

- **NixOS (`homelab`, `desktop-pc`)**: Retains `systemd.tmpfiles.rules` (`L+`) to allow headless operation without Home Manager.
- **Darwin (`macbook-air-m4-15`)**: Employs Home Manager `xdg.configFile."nvim".source = ./dotfiles/nvim;` or Darwin activation script to establish the symlink cleanly.
