# Contract: Shell Aliases & Design Guide

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Target File**: `docs/reference/shell-aliases.md`

---

## 1. Document Structure & Scope

The `docs/reference/shell-aliases.md` document serves as the complete technical cheat sheet and design specification for the workstation and server shell environments.

- **Breadcrumb Header**: `[← Back to README](../../README.md)`
- **Mandatory Sections**:
  1. **Dual-Shell Architecture Overview**:
     - Fish login shell (`laurent`), Bash for root and scripts, shared `systemdAliases` and `gitAliases`.
  2. **Service Management Shortcuts (`systemctl`)**:
     - Full table (`sc`, `scs`, `scr`, `scl`, `sc-start`, `sc-stop`, `sc-failed`).
  3. **Log Inspection Shortcuts (`journalctl`)**:
     - Full table (`jc`, `logs`, `logsf`, `jcu`, `jcuf`, `jcf`, `jcb`, `jce`).
  4. **Git Shortcuts (Oh-My-Zsh Style)**:
     - Exhaustive 25+ row table (`g`, `gst`, `ga`, `gaa`, `gco`, `gcb`, `gsw`, `gswc`, `gc`, `gcm`, `gca`, `gcam`, `gc!`, `gd`, `gl`, `gp`, `gpf`, `gb`, `glo`, `grb`, `gm`, `gsta`, `grh`, `gclean`).
  5. **Desktop Interactive Fish Extensions**:
     - Enhanced CLI commands (`ls` with `eza`, `cat` with `bat`, `y` with `yazi`, `b` with `btop`, `d` with `ncdu`, `take`).
  6. **Unified Nord Visual Theme**:
     - Hex color palette values (`#2E3440`–`#B48EAD`), component mappings across Noctalia, Niri, WezTerm, Ghostty, Neovim, VS Code, and Starship.
  7. **Dynamic Noctalia Wallpapers (`desktop-pc`)**:
     - Assets directory, random startup selection, keybindings (`Mod+Shift+W`, `Mod+Ctrl+W`).
  8. **Code Typography: FiraCode Nerd Font**:
     - Programming ligatures, Fontconfig fallbacks, editor and terminal font configurations.
  9. **Harmonized VS Code & Code Server Configuration**:
     - Shared extensions, settings, and LSP integrations (`modules/core/vscode.nix`).
  10. **Shared Modal Editor: Neovim & LazyVim**:
      - System-level engine, starter configuration symlink, and state persistence under `/persistent`.

---

## 2. Invariants

- All markdown tables MUST format with consistent pipe spacing and pass `just lint-md`.
- Links back to `../../README.md` at top and bottom of document.
