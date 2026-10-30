# Technical Research: Unified FiraCode Nerd Font Typography Across All Code & Terminal Views

**Feature Branch**: `020-firacode-nerd-font` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Overview

This research document consolidates the technical decisions, exact configuration options, and validation checks required to ensure `FiraCode Nerd Font` (with programming ligatures and Nerd Font v3 symbols) is used whenever code or terminal text is displayed across the `desktop-pc` stack and shared Neovim configuration.

---

## 1. System & User Monospace Font Resolution (`modules/desktop/fonts.nix`)

### Decision: Configure `fonts.fontconfig.defaultFonts.monospace` in Home Manager

- **Decision**: In `modules/desktop/fonts.nix`, expand `fonts.fontconfig` from `fonts.fontconfig.enable = true;` to:

  ```nix
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [
        "FiraCode Nerd Font"
        "FiraCode Nerd Font Mono"
      ];
    };
  };
  ```

- **Rationale**:
  - `modules/desktop/fonts.nix` installs three Nerd Font families (`nerd-fonts.fira-code`, `nerd-fonts.jetbrains-mono`, `nerd-fonts.meslo-lg`). Without an explicit `defaultFonts.monospace` preference in Fontconfig (`52-hm-default-fonts.conf`), applications requesting the generic `monospace` family (such as Google Chrome rendering `<code>`/`<pre>` blocks, Obsidian default code blocks, or system dialogs) may fall back to DejaVu Sans Mono, JetBrainsMono Nerd Font, or MesloLG Nerd Font.
  - Prioritizing `"FiraCode Nerd Font"` first and `"FiraCode Nerd Font Mono"` second ensures full ligature + icon support by default, with strict fixed-cell fallback where needed.
- **Alternatives Considered**:
  - *Removing `jetbrains-mono` and `meslo-lg` from `home.packages`*: Rejected because keeping them available as secondary installed fonts is harmless once Fontconfig explicitly prioritizes `FiraCode Nerd Font` for `monospace`.

---

## 2. Code Editors (`modules/desktop/editors.nix` & `modules/core/dotfiles/nvim/`)

### Decision 2.1: VS Code Code & Terminal Surfaces (`modules/desktop/editors.nix`)

- **Decision**: In `programs.vscode.profiles.default.userSettings`:
  - Retain `"editor.fontFamily" = "FiraCode Nerd Font";` and `"editor.fontLigatures" = true;`.
  - Retain `"terminal.integrated.fontFamily" = "FiraCode Nerd Font";` and `"terminal.integrated.fontLigatures.enabled" = true;`.
  - Add explicit `FiraCode Nerd Font` settings for auxiliary code-displaying surfaces in VS Code:
    - `"debug.console.fontFamily" = "FiraCode Nerd Font";`
    - `"scm.inputFontFamily" = "FiraCode Nerd Font";`
    - `"chat.editor.fontFamily" = "FiraCode Nerd Font";`
- **Rationale**: While VS Code's main editor and integrated terminal already use `FiraCode Nerd Font`, the Debug Console, Source Control commit input, and inline Chat code blocks have independent font family settings in VS Code that can otherwise fall back to `monospace` or `default`.

### Decision 2.2: Zed Editor Code Buffer & Integrated Terminal (`modules/desktop/editors.nix`)

- **Decision**: In `programs.zed-editor.userSettings`, add:

  ```nix
  buffer_font_family = "FiraCode Nerd Font";
  buffer_font_size = 12;
  buffer_font_features = {
    calt = true;
  };

  terminal = {
    font_family = "FiraCode Nerd Font";
    font_size = 12;
  };
  ```

- **Rationale**:
  - Previously, `programs.zed-editor.userSettings` did not specify `buffer_font_family` or `terminal.font_family`, causing Zed to default to its bundled `Zed Mono` font instead of `FiraCode Nerd Font`.
  - Setting `buffer_font_family = "FiraCode Nerd Font"` with `buffer_font_features = { calt = true; }` and `terminal.font_family = "FiraCode Nerd Font"` aligns Zed's editor buffer and built-in terminal drawer with VS Code and WezTerm.

### Decision 2.3: Neovim / LazyVim (`modules/core/dotfiles/nvim/lua/config/options.lua`)

- **Decision**: In `modules/core/dotfiles/nvim/lua/config/options.lua`, add:

  ```lua
  vim.opt.guifont = "FiraCode Nerd Font:h12"
  ```

- **Rationale**:
  - When Neovim runs inside a terminal emulator (WezTerm, Ghostty, VS Code integrated terminal, Zed integrated terminal), character cells, OpenType ligatures, and Nerd Font glyphs are rendered directly by the terminal emulator's configured `FiraCode Nerd Font`.
  - Setting `vim.opt.guifont = "FiraCode Nerd Font:h12"` ensures that if Neovim is ever launched via a graphical client (such as Neovide, goneovim, or nvim-qt), it also uses `FiraCode Nerd Font` at 12pt.
  - In headless SSH sessions on `homelab`, `vim.opt.guifont` is a pure Lua option with zero package dependencies, preserving `homelab`'s lightweight closure.

---

## 3. Terminal Emulators (`modules/desktop/terminal.nix` & `modules/desktop/apps.nix`)

### Decision 3.1: WezTerm (`modules/desktop/terminal.nix`)

- **Decision**: Retain the existing declarative configuration in `modules/desktop/terminal.nix`:

  ```lua
  config.font = wezterm.font('FiraCode Nerd Font')
  config.font_size = 11.5
  config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
  ```

- **Rationale**: Already configures `FiraCode Nerd Font` with contextual alternates and standard ligatures enabled.

### Decision 3.2: Ghostty (`modules/desktop/apps.nix`)

- **Decision**: In `programs.ghostty.settings` inside `modules/desktop/apps.nix`, add:

  ```nix
  ghostty = {
    enable = true;
    settings = {
      theme = "Nord";
      font-family = "FiraCode Nerd Font";
      font-feature = [
        "calt"
        "clig"
        "liga"
      ];
    };
  };
  ```

- **Rationale**:
  - Previously, `programs.ghostty.settings` only configured `theme = "Nord"`, leaving `font-family` unset (which defaults to Ghostty's bundled JetBrains Mono).
  - Setting `font-family = "FiraCode Nerd Font"` and `font-feature = [ "calt" "clig" "liga" ]` ensures Ghostty renders terminal text, CLI/TUI tools (`nvim`, `opencode`, `bat`, `lazygit`, `yazi`, `btop`, `fzf`), and programming ligatures identically to WezTerm.
  - Verified against `/nix/store/...-ghostty-1.3.1/bin/ghostty +show-config --default` that `font-family` and `font-feature` are valid Ghostty configuration keys.
