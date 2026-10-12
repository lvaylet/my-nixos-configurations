# Interface Contract: CLI & Toolchain Availability

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](../spec.md)

This contract defines the command-line interfaces, binaries, and version thresholds that must be available in the user environment for LazyVim.

---

## 1. Primary Editor Commands

| Command | Expected Target | Aliased Options | Description |
|---|---|---|---|
| `nvim` | `${pkgs.neovim}/bin/nvim` | N/A | Primary Neovim editor binary |
| `vim` | `${pkgs.neovim}/bin/nvim` | Symlink / alias | Compatibility alias for Vim |
| `vi` | `${pkgs.neovim}/bin/nvim` | Symlink / alias | Compatibility alias for Vi |

---

## 2. Runtime Dependency Commands

| Command | Minimum Version | Source Package | Upstream Purpose |
|---|---|---|---|
| `git` | 2.19.0+ | `pkgs.git` | Cloning `lazy.nvim` and plugin repositories |
| `gcc` | 12.0+ | `pkgs.gcc` | Compiling Tree-sitter parsers into shared libraries |
| `make` | 4.0+ | `pkgs.gnumake` | Compiling native plugin extensions (e.g., C extensions) |
| `rg` | 13.0+ | `pkgs.ripgrep` | Fast live pattern matching and grep search |
| `fd` | 8.0+ | `pkgs.fd` | Fast fuzzy file discovery |
| `wl-copy` | Any | `pkgs.wl-clipboard` | Wayland clipboard integration for copy |
| `wl-paste` | Any | `pkgs.wl-clipboard` | Wayland clipboard integration for paste |

---

## 3. Environment Variables

| Variable | Value | Purpose |
|---|---|---|
| `EDITOR` | `nvim` | Sets Neovim as the standard interactive editor for terminal sessions |
| `VISUAL` | `nvim` | Sets Neovim as the visual text editor for git and terminal tools |
