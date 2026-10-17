# Data Model: Unified FiraCode Nerd Font Typography Across All Code & Terminal Views

**Feature Branch**: `020-firacode-nerd-font` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Entities & Typography Mapping Model

### 1. Typography Profile (`TypographyProfile`)

The canonical font specification applied across all code and terminal surfaces:

| Property | Canonical Value | Purpose |
| --- | --- | --- |
| **Primary Font Family** | `FiraCode Nerd Font` | Monospace programming font with OpenType ligatures and Nerd Font v3 symbol glyphs |
| **Secondary Monospace Fallback** | `FiraCode Nerd Font Mono` | Strict fixed-advance icon variant registered as secondary fallback in Fontconfig |
| **Nix Package** | `pkgs.nerd-fonts.fira-code` | Declarative Nixpkgs Nerd Fonts derivation installed via `modules/desktop/fonts.nix` |
| **OpenType Ligature Features** | `calt`, `clig`, `liga` | Contextual alternates and standard ligatures for operators (`!=`, `==`, `->`, `=>`, `::`, `<=>`) |
| **Editor Font Size** | `12` (`12pt` / `:h12`) | Standard code buffer and integrated terminal font size across VS Code, Zed, and Neovim GUI |
| **Standalone Terminal Font Size** | `11.5` (WezTerm) / `12` (Ghostty default) | Ergonomic terminal cell sizing on `desktop-pc` |

---

### 2. Code & Terminal Surface Matrix (`CodeSurfaceTypographyMapping`)

| Component / Surface | Module / Dotfile Path | Configuration Option / Key | Target Value |
| --- | --- | --- | --- |
| **Fontconfig (`monospace`)** | `modules/desktop/fonts.nix` | `fonts.fontconfig.defaultFonts.monospace` | `[ "FiraCode Nerd Font" "FiraCode Nerd Font Mono" ]` |
| **VS Code (Editor)** | `modules/desktop/editors.nix` | `programs.vscode.profiles.default.userSettings` | `"editor.fontFamily" = "FiraCode Nerd Font"`, `"editor.fontLigatures" = true`, `"editor.fontSize" = 12` |
| **VS Code (Integrated Terminal)** | `modules/desktop/editors.nix` | `programs.vscode.profiles.default.userSettings` | `"terminal.integrated.fontFamily" = "FiraCode Nerd Font"`, `"terminal.integrated.fontLigatures.enabled" = true`, `"terminal.integrated.fontSize" = 12` |
| **VS Code (Debug / SCM / Chat)** | `modules/desktop/editors.nix` | `programs.vscode.profiles.default.userSettings` | `"debug.console.fontFamily" = "FiraCode Nerd Font"`, `"scm.inputFontFamily" = "FiraCode Nerd Font"`, `"chat.editor.fontFamily" = "FiraCode Nerd Font"` |
| **Zed Editor (Code Buffer)** | `modules/desktop/editors.nix` | `programs.zed-editor.userSettings` | `buffer_font_family = "FiraCode Nerd Font"`, `buffer_font_size = 12`, `buffer_font_features = { calt = true; }` |
| **Zed Editor (Integrated Terminal)** | `modules/desktop/editors.nix` | `programs.zed-editor.userSettings.terminal` | `font_family = "FiraCode Nerd Font"`, `font_size = 12` |
| **Neovim (TUI & GUI)** | `modules/core/dotfiles/nvim/lua/config/options.lua` | `vim.opt.guifont` (+ terminal font inheritance) | `vim.opt.guifont = "FiraCode Nerd Font:h12"` |
| **WezTerm** | `modules/desktop/terminal.nix` | `programs.wezterm.extraConfig` | `wezterm.font('FiraCode Nerd Font')`, `harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }` |
| **Ghostty** | `modules/desktop/apps.nix` | `programs.ghostty.settings` | `font-family = "FiraCode Nerd Font"`, `font-feature = [ "calt" "clig" "liga" ]` |

---

## Validation Rules & Invariants

1. **Universal Code Font Coverage**: Every code editor (VS Code, Zed, Neovim) and terminal emulator (WezTerm, Ghostty, VS Code terminal, Zed terminal) in the `desktop-pc` closure MUST explicitly specify `FiraCode Nerd Font` (`SC-001`).
2. **Fontconfig Default Monospace Priority**: `FiraCode Nerd Font` MUST be the first entry in `fonts.fontconfig.defaultFonts.monospace` so `fc-match monospace` resolves to `FiraCode Nerd Font` (`SC-002`).
3. **Ghostty Build-Time Config Validation**: `programs.ghostty.settings` MUST pass `ghostty +validate-config` during Home Manager derivation builds (`FR-005`).
4. **Host Isolation Invariant**: `homelab` MUST continue to evaluate with `enableHomeManager = false` and zero desktop font derivations added to its system closure (`FR-006`, `SC-004`).
