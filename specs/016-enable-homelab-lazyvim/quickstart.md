# Quickstart Validation Guide: Enable Shared LazyVim Neovim Configuration on Homelab

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This guide provides runnable validation scenarios to verify that the LazyVim Neovim configuration is shared cleanly between `desktop-pc` and `homelab`, adheres to module and preservation contracts, and passes all repository quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `016-enable-homelab-lazyvim`.
2. Nix with Flakes enabled (`nix-command flakes`) and `just` installed.

---

## Scenario 1: Verify Single Source of Truth & Module Contracts

Verify that the LazyVim dotfiles reside in `modules/core/dotfiles/nvim/`, that `modules/desktop/dotfiles/nvim/` no longer exists, and that both `desktop-pc` and `homelab` evaluate the identical `~/.config/nvim` source path.

```bash
# 1. Verify dotfiles directory location
test -d modules/core/dotfiles/nvim && ! test -d modules/desktop/dotfiles/nvim

# 2. Verify ~/.config/nvim source matches across desktop-pc and homelab
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.xdg.configFile.nvim.source
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.xdg.configFile.nvim.source
```

**Expected Outcome**:

- Both evaluations return the identical Nix store path for `dotfiles/nvim` as specified in [neovim-module-contract.md](contracts/neovim-module-contract.md).

---

## Scenario 2: Verify Neovim Configuration & Headless Closure Purity on `homelab`

Verify that `homelab` enables Neovim (`defaultEditor`, `viAlias`, `vimAlias`) via Home Manager while excluding graphical desktop editors (`vscode`, `zed-editor`).

```bash
# 1. Verify Neovim is enabled as default editor with vi/vim aliases on homelab
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.neovim.enable
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.neovim.defaultEditor
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.neovim.viAlias
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.neovim.vimAlias

# 2. Verify graphical editors are NOT enabled on homelab
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.vscode.enable
nix eval .#nixosConfigurations.homelab.config.home-manager.users.laurent.programs.zed-editor.enable

# 3. Verify graphical editors REMAIN enabled on desktop-pc
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.neovim.enable
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.enable
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.zed-editor.enable
```

**Expected Outcome**:

- `homelab` returns `true` for all `programs.neovim.*` checks and `false` for `programs.vscode.enable` and `programs.zed-editor.enable`.
- `desktop-pc` returns `true` for `programs.neovim.enable`, `programs.vscode.enable`, and `programs.zed-editor.enable`.

---

## Scenario 3: Verify Neovim State Preservation on `homelab`

Verify that `.local/share/nvim` and `.local/state/nvim` are registered for persistence on `homelab` per [homelab-preservation-contract.md](contracts/homelab-preservation-contract.md).

```bash
nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".users.laurent.directories
```

**Expected Outcome**:

- The returned JSON array includes entries for `.local/share/nvim` and `.local/state/nvim`.

---

## Scenario 4: Verify Formatting, Linting & Full Flake Checks

Run all repository quality gates to confirm zero errors or regressions across `desktop-pc`, `homelab`, and `iso`.

```bash
# 1. Format Nix files
just fmt

# 2. Run deadnix and statix linters
just lint

# 3. Evaluate all host system derivations
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath

# 4. Run full flake check suite
just check
```

**Expected Outcome**:

- All commands succeed with exit code 0 and zero warnings.
