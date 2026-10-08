# Data Model: NNN Stack Desktop Environment Migration

**Feature Branch**: `feat-migrate-to-niri-and-noctalia` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

## Entity Relationship Overview

```mermaid
erDiagram
    HOST_CONFIGURATION ||--|| DESKTOP_SESSION_PROFILE : enables
    HOST_CONFIGURATION ||--|{ USER_ENVIRONMENT_PROFILE : provisions
    USER_ENVIRONMENT_PROFILE ||--|| DESKTOP_SHELL_CONFIG : configures
    USER_ENVIRONMENT_PROFILE ||--|| TERMINAL_PROFILE : configures
    USER_ENVIRONMENT_PROFILE ||--|| TYPOGRAPHY_PROFILE : configures
    TERMINAL_PROFILE ||--|| SHELL_PROFILE : launches
    TERMINAL_PROFILE }|--|| TYPOGRAPHY_PROFILE : uses
    USER_ENVIRONMENT_PROFILE ||--|| EDITOR_PROFILE : configures
    EDITOR_PROFILE }|--|| TYPOGRAPHY_PROFILE : uses

    HOST_CONFIGURATION {
        string hostName "desktop-pc"
        boolean niri_enabled
        string display_manager "greetd"
        string greeter "tuigreet"
    }

    DESKTOP_SESSION_PROFILE {
        string compositor "niri"
        string session_binary "niri-session"
        string display_server "wayland"
        string portal_implementations "gnome, gtk"
    }

    USER_ENVIRONMENT_PROFILE {
        string userName "laurent"
        string homeDirectory "/home/laurent"
        string stateVersion "26.05"
    }

    DESKTOP_SHELL_CONFIG {
        string shell_name "noctalia"
        string config_format "toml"
        boolean bar_enabled
        boolean launcher_enabled
        boolean notifications_enabled
        boolean lockscreen_enabled
    }

    TERMINAL_PROFILE {
        string emulator "wezterm"
        string config_format "lua"
        string color_scheme "Catppuccin Mocha"
        float font_size 11.5
        boolean ligatures_enabled
    }

    SHELL_PROFILE {
        string shell_name "fish"
        boolean syntax_highlighting
        boolean autosuggestions
        boolean starship_prompt
        string default_interactive_shell
    }

    TYPOGRAPHY_PROFILE {
        string primary_font "FiraCode Nerd Font"
        string font_family "FiraCode Nerd Font"
        string opentype_features "calt, clig, liga"
        boolean ligatures_active
    }

    EDITOR_PROFILE {
        string editor_name "neovim"
        string manager "nvf"
        string theme "catppuccin-mocha"
        boolean lualine_enabled
        string guifont "FiraCode Nerd Font"
    }
```

---

## Entities & Attributes

### 1. `HOST_CONFIGURATION`
Represents the system-level target configuration (`machines/desktop-pc/configuration.nix` and `modules/nixos/desktop.nix`).
- **`hostName`** (string): Machine hostname (`desktop-pc`).
- **`niri_enabled`** (boolean): Whether the system-level Niri compositor package and session wrapper are enabled (`programs.niri.enable = true`).
- **`display_manager`** (string): System display manager service (`greetd`).
- **`greeter`** (string): Authentication UI greeter (`tuigreet`), configured to launch `niri-session`.
- **Validation**:
  - `desktopManager.cosmic.enable` MUST be `false` (or removed).
  - `displayManager.cosmic-greeter.enable` MUST be `false` (or removed).

### 2. `DESKTOP_SESSION_PROFILE`
Encapsulates runtime Wayland session attributes.
- **`compositor`** (string): The window manager / compositor binary (`niri`).
- **`session_binary`** (string): Path or command to initiate the session (`niri-session`).
- **`display_server`** (string): Standard display protocol (`wayland`).
- **`portal_implementations`** (string): Portals for screen sharing, open-file dialogs, and desktop settings (`xdg-desktop-portal-gnome`, `xdg-desktop-portal-gtk`).

### 3. `USER_ENVIRONMENT_PROFILE`
Home Manager user configuration root (`machines/desktop-pc/configuration.nix` -> `home-manager.users.${vars.userName}`).
- **`userName`** (string): System user identifier (`laurent`).
- **`homeDirectory`** (string): User home directory (`/home/laurent`).
- **`stateVersion`** (string): Home Manager compatibility pin (`26.05`).

### 4. `DESKTOP_SHELL_CONFIG`
Noctalia desktop shell settings (`modules/home-manager/noctalia.nix`).
- **`shell_name`** (string): `noctalia`.
- **`config_format`** (string): TOML.
- **`bar_enabled`** (boolean): Whether top/bottom system status bar is displayed.
- **`launcher_enabled`** (boolean): Whether fuzzy search application launcher is active.
- **`notifications_enabled`** (boolean): Whether native Wayland notification toasts are handled.
- **`lockscreen_enabled`** (boolean): Whether session lock surface is configured.
- **Validation**:
  - Automatically launched or executed when Niri session starts.

### 5. `TERMINAL_PROFILE`
WezTerm terminal emulator configuration (`modules/home-manager/wezterm.nix`).
- **`emulator`** (string): `wezterm`.
- **`config_format`** (string): Lua.
- **`color_scheme`** (string): Terminal palette (`Catppuccin Mocha`).
- **`font_size`** (float): Default text point size (e.g. `11.5` or `12.0`).
- **`ligatures_enabled`** (boolean): Whether Harfbuzz ligature features (`calt`, `clig`, `liga`) are active (MUST be `true`).
- **`default_prog`** (list of strings): Shell execution vector (`["fish"]`).

### 6. `SHELL_PROFILE`
Fish interactive shell configuration (`modules/home-manager/fish.nix`).
- **`shell_name`** (string): `fish`.
- **`syntax_highlighting`** (boolean): Native command highlighting (MUST be `true`).
- **`autosuggestions`** (boolean): Inline history completion (MUST be `true`).
- **`starship_prompt`** (boolean): Whether Starship prompt is integrated into Fish (MUST be `true`).
- **Validation**:
  - Non-interactive scripts and `/bin/sh` executions MUST NOT run through Fish to preserve POSIX compatibility.

### 7. `TYPOGRAPHY_PROFILE`
System and user typography configuration (`modules/home-manager/fonts.nix`).
- **`primary_font`** (string): `FiraCode Nerd Font`.
- **`font_family`** (string): Monospace font family name (`FiraCode Nerd Font`).
- **`opentype_features`** (string): Contextual alternates (`calt=1`, `clig=1`, `liga=1`).
- **`ligatures_active`** (boolean): Active state for code comparison and arrow symbols.

### 8. `EDITOR_PROFILE`
Neovim editor environment (`modules/nixos/neovim.nix`).
- **`editor_name`** (string): `neovim`.
- **`manager`** (string): `nvf` (Neovim configuration framework via Flake).
- **`theme`** (string): `catppuccin` style `mocha`.
- **`lualine_enabled`** (boolean): Statusline with Nerd Font icon support.
- **`guifont`** (string): `FiraCode Nerd Font:h12` for graphical frontends.
