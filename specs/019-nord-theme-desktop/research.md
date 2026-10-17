# Technical Research: System-Wide Nord Theme Across the Desktop-PC Stack

**Feature Branch**: `019-nord-theme-desktop` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Overview

This research document consolidates the technical decisions, exact configuration schemas, and official Nord color mappings required to unify the visual theme across all 17 themeable components of the `desktop-pc` stack (and shared `core.neovim` / `core.git` modules).

---

## 1. Canonical Nord Color Palette Reference

### Decision: Official 16-Color Nord Palette (`#2E3440` – `#B48EAD`)

- **Decision**: Use the official 16-color Nord palette across all custom hex definitions (Niri, Starship, Fzf, Yazi, Lazygit, Fish, Btop):
  - **Polar Night** (Dark backgrounds & surfaces):
    - `nord0`: `#2E3440` (base background)
    - `nord1`: `#3B4252` (elevated surface / status bar / selection background)
    - `nord2`: `#434C5E` (active selection / highlight surface)
    - `nord3`: `#4C566A` (inactive borders / comments / muted UI)
  - **Snow Storm** (Light foregrounds & text):
    - `nord4`: `#D8DEE9` (default foreground text)
    - `nord5`: `#E5E9F0` (secondary bright text)
    - `nord6`: `#ECEFF4` (emphasized / bold / heading text)
  - **Frost** (Primary bluish-arctic accents):
    - `nord7`: `#8FBCBB` (frozen polar water / teal-cyan)
    - `nord8`: `#88C0D0` (pure ice / bright cyan — primary focus & active border accent)
    - `nord9`: `#81A1C1` (arctic waters / medium blue)
    - `nord10`: `#5E81AC` (deep arctic ocean / dark blue)
  - **Aurora** (Semantic status & syntax accents):
    - `nord11`: `#BF616A` (red — errors / urgent alerts / deletions)
    - `nord12`: `#D08770` (orange — warnings / modifiers / directory accents)
    - `nord13`: `#EBCB8B` (yellow — caution / Git branch & modified state)
    - `nord14`: `#A3BE8C` (green — success / additions / language toolchains)
    - `nord15`: `#B48EAD` (purple — numbers / special tokens / time segments)
- **Rationale**: Using the exact canonical hex codes guarantees 100% visual consistency between components that ship a built-in `"Nord"` theme (Noctalia, VS Code, WezTerm, Ghostty, Bat, OpenCode) and components configured via explicit hex palettes (Niri, Starship, Fzf, Yazi, Lazygit).
- **Alternatives Considered**:
  - *Mixing Nord with Onenord or Nordfox variants*: Rejected to preserve strict color uniformity across adjacent windows.

---

## 2. Desktop Session, Compositor, Greeter & Bootloader

### Decision 2.1: Noctalia Built-in `Nord` Palette with Static App Configs

- **Decision**: In `modules/desktop/dotfiles/noctalia.toml`, set:
  ```toml
  [theme]
  builtin = "Nord"
  mode = "dark"
  source = "builtin"

      [theme.templates]
      builtin_ids = []
  ```
- **Rationale**:
  - Inspection of Noctalia's C++ source (`src/theme/builtin_palettes.cpp`) confirms that `"Nord"` is one of the 10 compiled-in palettes (`Ayu`, `Catppuccin`, `Dracula`, `Eldritch`, `Gruvbox`, `Kanagawa`, `Noctalia`, `Nord`, `Rosé Pine`, `Tokyo-Night`) with exact Polar Night (`#2e3440`, `#3b4252`), Snow Storm (`#eceff4`, `#d8dee9`), Frost (`#8fbcbb`, `#88c0d0`, `#5e81ac`), and Aurora (`#bf616a`) definitions.
  - Using `source = "builtin"` eliminates network calls to `api.noctalia.dev` at startup and works 100% hermetically offline.
  - Setting `builtin_ids = []` prevents Noctalia's runtime `apply.sh` hooks from attempting to rewrite `~/.config/niri/config.kdl` and `~/.config/wezterm/wezterm.lua`, which are read-only Home Manager symlinks into `/nix/store`.
- **Alternatives Considered**:
  - *`source = "community"` with a community Nord palette*: Requires runtime network fetch and local state caching; unnecessary since `"Nord"` is compiled directly into Noctalia.

### Decision 2.2: Niri Window Focus Ring and Border Colors

- **Decision**: In `modules/desktop/dotfiles/niri/config.kdl`, update `focus-ring` and `border` inside `layout`:
  - `focus-ring`: `active-color "#88c0d0"` (`nord8`), `inactive-color "#4c566a"` (`nord3`).
  - `border`: `active-color "#88c0d0"` (`nord8`), `inactive-color "#4c566a"` (`nord3`), `urgent-color "#bf616a"` (`nord11`).
- **Rationale**: Replaces the hardcoded Catppuccin Mocha Mauve (`#cba6f7`) and Surface1 (`#45475a`) focus ring colors with Nord Frost (`#88c0d0`) and Polar Night (`#4c566a`).

### Decision 2.3: Tuigreet Login Theme & Limine Bootloader Wallpapers

- **Decision**:
  - In `modules/desktop/session.nix`, pass `--theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white'` to `tuigreet` so the KMS console login screen uses cool cyan/blue/white Nord-aligned ANSI colors.
  - In `modules/core/base.nix`, replace `catppuccin-macchiato.gnomeFilePath` and `nineish-catppuccin-macchiato.gnomeFilePath` in `boot.loader.limine.style.wallpapers` with `nineish-dark-gray.gnomeFilePath` and `simple-blue.gnomeFilePath` (alongside existing `mosaic-blue`, `simple-dark-gray-bootloader`, and `waterfall`).
- **Rationale**: Removes all Catppuccin-branded visual assets from the boot sequence while using verified attributes from `pkgs.nixos-artwork.wallpapers`.

---

## 3. Terminal Emulators (WezTerm & Ghostty)

### Decision: Native Built-in `nord` / `Nord` Color Schemes

- **Decision**:
  - **WezTerm** (`modules/desktop/terminal.nix`): Set `config.color_scheme = 'nord'` (replacing `'Catppuccin Mocha'`).
  - **Ghostty** (`modules/desktop/apps.nix`): Set `programs.ghostty.settings.theme = "Nord";` (verified in `/nix/store/...-ghostty-1.3.1/share/ghostty/themes/Nord`).
- **Rationale**: Both terminal emulators ship the official Nord palette out of the box. Note that Ghostty's Home Manager module runs `ghostty +validate-config` on build/activation, and its built-in theme file is capitalized as `"Nord"`, whereas WezTerm's built-in scheme catalog uses lowercase `'nord'`.

---

## 4. Code Editors & IDEs (VS Code, Neovim, Zed)

### Decision 4.1: VS Code (`modules/desktop/editors.nix`)

- **Decision**: Retain `pkgs.vscode-extensions.arcticicestudio.nord-visual-studio-code` and `"workbench.colorTheme" = "Nord";` in `modules/desktop/editors.nix`.
- **Rationale**: Already uses the official Nord extension and theme; serves as the reference baseline mentioned by the user.

### Decision 4.2: Neovim / LazyVim (`modules/core/dotfiles/nvim/`)

- **Decision**:
  - Create `modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua` declaring `shaunsingh/nord.nvim` (or `gbprod/nord.nvim`) and configuring `LazyVim/LazyVim` `opts = { colorscheme = "nord" }`.
  - Update `modules/core/dotfiles/nvim/lua/config/lazy.lua` line 35 from `install = { colorscheme = { "tokyonight", "habamax" } }` to `install = { colorscheme = { "nord", "habamax" } }`.
- **Rationale**:
  - `gbprod/nord.nvim` is a modern, actively maintained Lua Neovim colorscheme built specifically for Tree-sitter, LSP semantic tokens, Lualine, Telescope, Neo-tree, Bufferline, Notify, and LazyVim plugins, registering the `"nord"` colorscheme name.
  - Because `modules/core/neovim.nix` links `modules/core/dotfiles/nvim` to `~/.config/nvim` via `systemd.tmpfiles.rules` (`L+`), adding `lua/plugins/colorscheme.lua` is 100% declarative and automatically applies to both `desktop-pc` and `homelab` without requiring Home Manager on `homelab`.
- **Alternatives Considered**:
  - *Modifying `lua/plugins/example.lua`*: `example.lua` is upstream LazyVim's disabled reference template (`if true then return {} end`); keeping a dedicated `lua/plugins/colorscheme.lua` is cleaner and follows LazyVim best practices.

### Decision 4.3: Zed Editor (`modules/desktop/editors.nix`)

- **Decision**: In `programs.zed-editor`:
  - Replace `"one-dark-pro"` in `extensions` with `"nord"`.
  - Set `userSettings.theme` to `{ mode = "dark"; light = "One Light"; dark = "Nord"; }`.
- **Rationale**: Installs the official Zed `nord` extension automatically and activates the `Nord` dark theme by default.

---

## 5. Shell Prompt & Interactive CLI/TUI Stack

### Decision 5.1: Starship Prompt (`modules/desktop/dotfiles/starship.toml`)

- **Decision**: Replace `palette = 'catppuccin_macchiato'` and the four `catppuccin_*` palette tables with `palette = 'nord'` and a `[palettes.nord]` table mapping semantic color names to official Nord hex codes:
  - `polar_night_0 = "#2e3440"` (`crust` replacement for dark text on colored powerline pills)
  - `polar_night_1 = "#3b4252"`, `polar_night_2 = "#434c5e"`, `polar_night_3 = "#4c566a"`
  - `snow_storm_0 = "#d8dee9"`, `snow_storm_1 = "#e5e9f0"`, `snow_storm_2 = "#eceff4"`
  - `frost_0 = "#8fbcbb"`, `frost_1 = "#88c0d0"`, `frost_2 = "#81a1c1"`, `frost_3 = "#5e81ac"`
  - `red = "#bf616a"`, `orange = "#d08770"`, `yellow = "#ebcb8b"`, `green = "#a3be8c"`, `purple = "#b48ead"`
  - Update powerline segment progression (`red` -> `orange` -> `yellow` -> `green` -> `frost_1` -> `purple`) with `fg:polar_night_0` (`#2e3440`) for high-contrast legibility.
- **Rationale**: Preserves the exact powerline pill layout and Nerd Font icons while shifting all segment colors to Nord Aurora, Frost, and Polar Night.

### Decision 5.2: Fish Shell Syntax Highlighting (`modules/desktop/shell.nix`)

- **Decision**: Add Nord syntax highlighting and pager color variables (`fish_color_*` and `fish_pager_color_*`) in `programs.fish.interactiveShellInit` inside `modules/desktop/shell.nix`.
- **Rationale**: Ensures command-line tokens (commands in Frost `#88c0d0`/`#81a1c1`, strings in Aurora Green `#a3be8c`, errors in Aurora Red `#bf616a`, comments in Polar Night `#4c566a`, autosuggestions in `#4c566a`) match the Nord specification.

### Decision 5.3: CLI & TUI Utilities (`modules/desktop/apps.nix` & `modules/core/git.nix`)

- **Decision**:
  - **OpenCode** (`modules/desktop/apps.nix`): Set `programs.opencode.tui.theme = "nord";` (replacing `"catppuccin-macchiato"`).
  - **Bat** (`modules/desktop/apps.nix`): Set `programs.bat.config.theme = "Nord";` (built-in Sublime syntax theme in `bat`).
  - **Fzf** (`modules/desktop/apps.nix`): Configure `programs.fzf.colors` with Nord hex codes (`bg = "#2e3440"`, `"bg+" = "#3b4252"`, `fg = "#d8dee9"`, `"fg+" = "#eceff4"`, `hl = "#88c0d0"`, `"hl+" = "#8fbcbb"`, `info = "#ebcb8b"`, `prompt = "#81a1c1"`, `pointer = "#88c0d0"`, `marker = "#a3be8c"`, `spinner = "#b48ead"`, `header = "#5e81ac"`, `border = "#4c566a"`).
  - **Yazi** (`modules/desktop/apps.nix`): Configure `programs.yazi.theme` with Nord colors for manager (`mgr`), status/mode bar, tabs, and selection indicators.
  - **Btop** (`modules/desktop/apps.nix`): Enable `programs.btop = { enable = true; settings.color_theme = "nord"; };` (matching the existing `b = "btop"` alias in `modules/desktop/shell.nix`).
  - **Lazygit** (`modules/core/git.nix`): Configure `programs.lazygit.settings.gui.theme` with Nord colors (`activeBorderColor = ["#88c0d0" "bold"]`, `inactiveBorderColor = ["#4c566a"]`, `optionsTextColor = ["#81a1c1"]`, `selectedLineBgColor = ["#3b4252"]`, `cherryPickedCommitBgColor = ["#434c5e"]`, `cherryPickedCommitFgColor = ["#88c0d0"]`, `unstagedChangesColor = ["#bf616a"]`, `defaultFgColor = ["#d8dee9"]`, `searchingActiveBorderColor = ["#ebcb8b"]`).
- **Rationale**: Every single TUI/CLI utility in `desktop-pc`'s stack supports native declarative theming in Home Manager without adding external flake inputs. Note that `modules/core/git.nix` defines `flake.modules.core.git.homeManager`, which is only evaluated on hosts with `enableHomeManager = true` (`desktop-pc`), so adding `lazygit.settings.gui.theme` has zero impact on `homelab`'s Home Manager-free closure.
