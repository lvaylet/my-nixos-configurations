# Contract: Niri Keybindings & Window Rules

**Feature**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](../spec.md)

---

## 1. Keybindings (`modules/desktop/dotfiles/niri/config.kdl`)

The Niri window manager configuration replaces internal unnotified screenshot actions with `screenshot-tool` calls:

```kdl
    Print hotkey-overlay-title="Capture: Interactive Region" { spawn "screenshot-tool" "region"; }
    Ctrl+Print hotkey-overlay-title="Capture: Full Screen" { spawn "screenshot-tool" "screen"; }
    Alt+Print hotkey-overlay-title="Capture: Active Window" { spawn "screenshot-tool" "window"; }
```

### Invariants

- Pressing `Print` launches `screenshot-tool region`.
- Pressing `Ctrl+Print` launches `screenshot-tool screen`.
- Pressing `Alt+Print` launches `screenshot-tool window`.
- The hotkey overlay titles document the actions in Niri's hotkey help HUD (`Mod+Shift+/`).

---

## 2. Window Rules for Annotation Editor

To ensure the Satty markup window appears as a floating dialog over the current workspace rather than expanding into a tiled column:

```kdl
window-rule {
    match app-id=r#"^com\.gabm\.satty$"#
    open-floating true
}
```

### Invariants

- When launched from notification action `"annotate"`, Satty opens as a floating window.
- Closing or completing Satty exits cleanly and restores window manager focus to the previously active application.
