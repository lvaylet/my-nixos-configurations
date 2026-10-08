# Nix Module Interface Contract: Desktop Environment (NNN Stack)

**Feature**: `004-switch-to-niri-noctalia`
**Status**: Proposed Contract

## Overview

This contract governs the module boundaries, exported options, and integration points for the Niri compositor, Noctalia desktop shell, WezTerm terminal, Fish shell, and typography configuration.

---

## 1. System-Level Desktop Module (`modules/nixos/desktop.nix`)

The system-level desktop module declares graphical environment prerequisites, compositor capabilities, and session greeters for host machines (`desktop-pc`).

### Interface Specification

```nix
{ pkgs, ... }: {
  # 1. Enable Wayland Compositor (Niri)
  programs.niri = {
    enable = true;
    # Native NixOS package and systemd integration
  };

  # 2. Configure Wayland Display Manager (Greetd + Tuigreet)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # 3. Enable Fish System Integration (for /etc/shells & vendor completions)
  programs.fish.enable = true;

  # 4. Invariants
  # - services.desktopManager.cosmic MUST NOT be enabled
  # - services.displayManager.cosmic-greeter MUST NOT be enabled
  # - services.system76-scheduler MAY be removed or kept as an independent scheduler
}
```

---

## 2. Flake Inputs Contract (`flake.nix`)

To provide Noctalia, `flake.nix` declares an upstream input:

```nix
{
  inputs = {
    # Existing inputs: nixpkgs, home-manager, nvf, git-hooks
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

---

## 3. User-Level Module Contracts (`modules/home-manager/`)

### A. Niri Compositor Configuration (`modules/home-manager/niri.nix`)

Manages user-level compositor bindings, layout, autostart, and window rules:

- **Path**: `xdg.configFile."niri/config.kdl"` or static link to `modules/home-manager/dotfiles/niri/config.kdl`.
- **Autostart**:
  - Spawns `noctalia` upon session start (`spawn-at-startup "noctalia"`).
  - Spawns xdg-desktop-portal-wlr/gnome as needed.
- **Terminal Hotkey**: Binds `Mod+Return` (or `Super+Return`) to spawn `wezterm`.
- **Launcher Hotkey**: Binds `Mod+Space` or `Mod+D` to spawn Noctalia launcher (`noctalia ipc launcher toggle` or `noctalia launcher`).

### B. Noctalia Shell Configuration (`modules/home-manager/noctalia.nix`)

Integrates Noctalia's Home Manager module:

```nix
{ inputs, pkgs, ... }: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    # Declarative TOML settings for bars, widgets, launcher, notifications
  };
}
```

### C. WezTerm Terminal Configuration (`modules/home-manager/wezterm.nix`)

Configures WezTerm as the primary GPU-accelerated terminal:

```nix
{ pkgs, ... }: {
  programs.wezterm = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      config.font = wezterm.font('FiraCode Nerd Font')
      config.font_size = 11.5
      config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
      config.color_scheme = 'Catppuccin Mocha'
      config.default_prog = { 'fish' }
      config.enable_wayland = true
      config.window_close_confirmation = 'NeverPrompt'

      return config
    '';
  };
}
```

### D. Fish Shell Configuration (`modules/home-manager/fish.nix`)

Configures Fish for interactive productivity:

```nix
{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting ""
    '';
  };

  # Ensure starship integrates with Fish
  programs.starship.enableFishIntegration = true;
}
```

### E. Fonts & Ligatures Verification (`modules/home-manager/fonts.nix`)

Ensures `nerd-fonts.fira-code` is installed and registered:

```nix
{ pkgs, ... }: {
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
  ];

  fonts.fontconfig.enable = true;
}
```
