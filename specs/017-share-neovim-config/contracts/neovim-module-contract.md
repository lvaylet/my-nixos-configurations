# Interface Contract: Shared System-Level Neovim Module (`core.neovim`)

**Branch**: `017-share-neovim-config` | **Date**: 2026-10-17 | **Spec**: [spec.md](../spec.md)

---

## 1. Dendritic Module Contract (`modules/core/neovim.nix`)

- **Attribute Path**: `flake.modules.core.neovim.nixos`
- **Module Signature**: `{pkgs, vars, ...}: { ... }`
- **Host Consumers**:
  - `modules/hosts/desktop-pc.nix` (via `features = with config.flake.modules; [ ... core.neovim ... ]`)
  - `modules/hosts/homelab.nix` (via `features = with config.flake.modules; [ ... core.neovim ... ]`)

### Required NixOS Configuration Outputs

1. **Neovim Program Configuration**:
   - `programs.neovim.enable = true`
   - `programs.neovim.defaultEditor = true`
   - `programs.neovim.viAlias = true`
   - `programs.neovim.vimAlias = true`
   - `programs.neovim.withNodeJs = true`
   - `programs.neovim.withPython3 = true`

2. **System Packages (`environment.systemPackages`)**:
   - `git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`

3. **Systemd Tmpfiles Symlink (`systemd.tmpfiles.rules`)**:
   - `"d /home/${vars.userName}/.config 0755 ${vars.userName} users -"`
   - `"L+ /home/${vars.userName}/.config/nvim - - - - ${./dotfiles/nvim}"`

---

## 2. Desktop Editors Module Contract (`modules/desktop/editors.nix`)

- **Attribute Path**: `flake.modules.desktop.editors.homeManager`
- **Responsibilities**:
  - Installs `pkgs.wl-clipboard` in `home.packages` for Wayland clipboard integration on `desktop-pc`.
  - Configures `programs.vscode` and `programs.zed-editor`.
  - MUST NOT define `programs.neovim` or `xdg.configFile."nvim"`.

---

## 3. Preservation Contract (`modules/core/preservation.nix`)

- **Attribute Path**: `preservation.preserveAt."/persistent".users.${vars.userName}.directories`
- **Required Entries**:
  - `".local/share/nvim"`
  - `".local/state/nvim"`
