# Technical Research: NNN Stack Desktop Migration (Niri + Noctalia)

**Feature Branch**: `feat-migrate-to-niri-and-noctalia` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

## Overview

This research document consolidates architectural investigations, technology evaluations, and implementation patterns required to replace the COSMIC desktop environment with the NNN stack (NixOS + Niri + Noctalia), alongside WezTerm as the terminal emulator, Fish as the interactive shell, and FiraCode Nerd Font with ligatures across terminal and editor environments.

---

## 1. Wayland Window Management & Compositor Layer

### Decision: Native NixOS `programs.niri.enable` with User KDL Configuration

- **Decision**: Enable the Niri scrollable-tiling Wayland compositor at the system level using `programs.niri.enable = true` in `modules/nixos/desktop.nix`, and configure user keybindings, outputs, window rules, and autostart in a dedicated Home Manager module `modules/home-manager/niri.nix` with KDL configuration managed via `xdg.configFile."niri/config.kdl"`.
- **Rationale**:
  - `programs.niri.enable` is natively integrated into NixOS (`nixpkgs`), providing out-of-the-box systemd user services, `niri-session` desktop entry, Polkit authentication agent integration, and portal coordination (`xdg-desktop-portal-gnome` / `xdg-desktop-portal-gtk`).
  - Niri's infinite horizontal scrollable tiling layout offers predictable window placement without complex tiling algorithms, aligning with modern productivity ergonomics.
  - Keeping static KDL configuration under `modules/home-manager/dotfiles/niri/config.kdl` strictly honors the project constitution (Article II & IV).
- **Alternatives Considered**:
  - *`niri-flake` (external flake)*: Evaluated as a potential source for bleeding-edge builds and Home Manager options, but rejected to avoid unnecessary flake inputs when `nixpkgs` already packages Niri 26.04+ natively with upstream NixOS modules.
  - *Retaining COSMIC*: Rejected per user requirements to replace COSMIC entirely.

---

## 2. Desktop Shell, Status Bar & Launcher Layer

### Decision: Noctalia Desktop Shell via Flake Input & Home Manager Module

- **Decision**: Integrate Noctalia (`github:noctalia-dev/noctalia`) via `flake.nix` input pinned to upstream main and following `nixpkgs`. Deploy its user configuration via a new `modules/home-manager/noctalia.nix` module utilizing Noctalia's Home Manager module (`programs.noctalia`).
- **Rationale**:
  - Noctalia is a unified, native Wayland desktop shell designed specifically for Wayland layer-shell compositors (with first-class Niri support). It replaces disparate components (Waybar, Rofi/Wofi, Dunst/Mako, Swaylock, Swaybg) with a single, coherent, OpenGL ES-accelerated shell layer.
  - Upstream Noctalia provides official `homeModules.default` and `nixosModules.default` directly in its flake, ensuring native declarative support with type-checked options and TOML configuration generation.
  - It handles bar widgets, application launcher, control center, notification daemon, clipboard manager, and session control seamlessly within Niri.
- **Alternatives Considered**:
  - *Assembling discrete Wayland utilities (Waybar + Wofi + Mako + Hyprlock)*: Common in older Wayland rices, but significantly higher maintenance overhead, fragmented configuration formats, and inconsistent visual themes compared to the unified Noctalia shell.
  - *Quickshell / AGS (Aylur's GTK Shell)*: Powerful but requires maintaining extensive custom JavaScript/TypeScript or QML UI codebases, violating the goal of a clean, maintainable desktop shell.

---

## 3. Display Manager & Session Authentication

### Decision: Greetd with Tuigreet

- **Decision**: Replace `services.displayManager.cosmic-greeter` with `services.greetd` running `tuigreet` configured to launch `niri-session`.
- **Rationale**:
  - `greetd` is lightweight, console/KMS-based, and completely independent of any heavyweight desktop environment (unlike GDM or SDDM which pull large GNOME or Qt dependency trees).
  - `tuigreet` runs cleanly on top of KMS console, handles graphical user logins gracefully, remembers the last session, and directly launches `niri-session` via systemd.
  - Completely eliminates all COSMIC display manager services, greeters, and session daemons.
- **Alternatives Considered**:
  - *SDDM (Simple Desktop Display Manager)*: Reliable for Wayland, but brings in heavy Qt dependencies and complex theme management.
  - *GDM (GNOME Display Manager)*: Pulls in large parts of GNOME shell and Mutter, which is unnecessary for a lean Niri workstation.
  - *Auto-login (agetty)*: Bypasses authentication security; a proper login greeter ensures session protection.

---

## 4. Terminal Emulator Architecture

### Decision: WezTerm with Declarative Lua Configuration

- **Decision**: Add `modules/home-manager/wezterm.nix` enabling `programs.wezterm.enable = true;` and configuring font family, size, ligatures, window padding, and default interactive shell. Replace or complement `ghostty.nix` in `machines/desktop-pc/configuration.nix`.
- **Rationale**:
  - WezTerm is a GPU-accelerated, cross-platform terminal emulator with mature Wayland support, rich typography handling (explicit Harfbuzz OpenType feature control), and built-in multiplexing.
  - Home Manager natively supports WezTerm through `programs.wezterm`, allowing configuration via Lua strings or dotfiles.
  - Font ligatures are enabled out of the box in WezTerm, and can be fine-tuned via `harfbuzz_features = {"calt=1", "clig=1", "liga=1"}`.
- **Alternatives Considered**:
  - *Ghostty*: Currently configured in the repository, but user specifically requested WezTerm.
  - *Alacritty / Kitty*: Fast, but WezTerm provides superior font ligature controls, Lua scripting, and Wayland compatibility.

---

## 5. Interactive Shell Architecture

### Decision: Fish Shell for Interactive Sessions with POSIX Sh/Bash Fallback

- **Decision**: Enable Fish system-wide via `programs.fish.enable = true;` in `modules/nixos/base.nix` (or `desktop.nix`) to register `/run/current-system/sw/bin/fish` in `/etc/shells` and vendor completions. Configure interactive user shell in Home Manager via `programs.fish.enable = true;` in `modules/home-manager/fish.nix`, and configure WezTerm's `default_prog` to launch Fish.
- **Rationale**:
  - Fish provides instant autosuggestions, syntax highlighting, and tab completions with zero manual plugin configuration.
  - Starship prompt (`modules/home-manager/starship.nix`) integrates natively with Fish (`programs.starship.enableFishIntegration = true`).
  - System scripting (`/bin/sh`, Bash scripts, Nix derivation builders, CI scripts) remains 100% untouched because NixOS always invokes scripts via explicit shebangs (`#!/bin/sh` or `#!/usr/bin/env bash`), guaranteeing total POSIX compatibility.
- **Alternatives Considered**:
  - *Zsh with heavy plugins (zsh-autosuggestions, fast-syntax-highlighting)*: Currently present in `modules/home-manager/_zsh.nix`, but slower startup latency and more complex maintenance than Fish's native C++ implementation.
  - *Changing system-wide default shell for root*: Strongly discouraged in NixOS; Fish should be the interactive shell for regular users while root and system services retain bash/sh.

---

## 6. Typography, Glyphs & Ligatures Integration

### Decision: FiraCode Nerd Font with Explicit Ligatures in WezTerm & Neovim

- **Decision**:
  - Ensure `nerd-fonts.fira-code` is active in `modules/home-manager/fonts.nix` and `fonts.fontconfig.enable = true`.
  - In WezTerm: Set `font = wezterm.font("FiraCode Nerd Font")` with standard calt/liga features.
  - In Neovim (`modules/nixos/neovim.nix` via `nvf`): Neovim inside WezTerm automatically inherits font rendering and OpenType ligatures from WezTerm. In addition, set `vim.options.guifont = "FiraCode Nerd Font:h12"` or appropriate GUI options for any graphical Neovim clients.
- **Rationale**:
  - FiraCode is widely recognized for clean programming ligatures (`!=`, `==`, `===`, `<=`, `>=`, `->`, `=>`, `/*`, `*/`, `::`).
  - Nerd Font patching adds complete symbol coverage for file icons, Git branches, and statusline glyphs (lualine).
- **Alternatives Considered**:
  - *JetBrains Mono Nerd Font*: Also high quality, but user explicitly specified FiraCode Nerd Font.
  - *Pure FiraCode without Nerd Font glyphs*: Lacks required developer glyphs for Neovim's filetree (`nvimTree`) and statusline (`lualine`).

---

## 7. Migration & Rollback Strategy

### Decision: Clean Module Swap with Generation Rollback Safety

- **Decision**:
  - Retire `modules/nixos/desktop.nix` COSMIC services completely.
  - Introduce Niri + Greetd in `modules/nixos/desktop.nix`.
  - In `machines/desktop-pc/configuration.nix`, swap `ghostty.nix` and `_zsh.nix` for `wezterm.nix`, `fish.nix`, `niri.nix`, and `noctalia.nix`.
  - Prior NixOS bootloader generations (Limine) retain COSMIC desktop definitions, enabling immediate rollback if needed.
- **Rationale**:
  - Conforms to Constitution Principle V (Safe Deployment & Rollback).
  - Prevents conflict between COSMIC background services (`cosmic-session`, `cosmic-app-library`) and Niri/Noctalia.
