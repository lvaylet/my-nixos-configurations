# Keybindings & Session Control Interface Contract

**Feature**: `004-switch-to-niri-noctalia`
**Status**: Proposed Contract

## Overview

This contract specifies standard keyboard shortcuts, session management signals, and IPC interaction behaviors across Niri, Noctalia, and WezTerm.

---

## 1. Niri Keyboard Control Contract

The default modifier key is `Mod` (`Super` / `Windows key`).

| Keybinding | Action | Target / IPC Command |
|---|---|---|
| `Mod + Return` | Launch primary terminal | `spawn "wezterm"` |
| `Mod + Space` / `Mod + D` | Toggle application launcher | `spawn "noctalia" "ipc" "launcher" "toggle"` |
| `Mod + Q` | Close active window | `close-window` |
| `Mod + H` / `Mod + Left` | Focus window left | `focus-column-left` |
| `Mod + L` / `Mod + Right` | Focus window right | `focus-column-right` |
| `Mod + J` / `Mod + Down` | Focus window down | `focus-window-down` |
| `Mod + K` / `Mod + Up` | Focus window up | `focus-window-up` |
| `Mod + Shift + H` / `Left` | Move column left | `move-column-left` |
| `Mod + Shift + L` / `Right`| Move column right | `move-column-right` |
| `Mod + F` | Toggle window fullscreen | `fullscreen-window` |
| `Mod + Shift + E` | Session power menu | `spawn "noctalia" "ipc" "session" "toggle"` |
| `Mod + Shift + L` | Lock screen | `spawn "noctalia" "ipc" "lock"` |

---

## 2. Noctalia IPC & Service Contract

Noctalia responds to command-line IPC triggers over its runtime socket:

- **`noctalia ipc launcher toggle`**: Opens/closes the fuzzy search application launcher.
- **`noctalia ipc session toggle`**: Opens the logout, reboot, shutdown confirmation overlay.
- **`noctalia ipc lock`**: Activates the Wayland session lock screen.
- **`noctalia ipc notifications toggle`**: Opens the notification center / history panel.
- **`noctalia ipc reload`**: Hot-reloads TOML configuration without restarting the session.

---

## 3. WezTerm Typography & Rendering Contract

WezTerm MUST honor the following visual and rendering invariants:

- **Font Family**: `"FiraCode Nerd Font"` (exact match).
- **OpenType Contextual Alternates (`calt`)**: Active (`1`).
- **Standard Ligatures (`liga`)**: Active (`1`).
- **Contextual Ligatures (`clig`)**: Active (`1`).
- **Wayland Protocol**: `enable_wayland = true`.
- **Default Interactive Shell**: `default_prog = { 'fish' }`.
- **Glyph Fallback**: Nerd Font icons for git status, file trees, and lualine symbols must render without missing glyph boxes.
