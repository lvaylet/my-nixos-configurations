# Module Contract: Desktop Editors Module (`modules/desktop/editors.nix`)

**Contract ID**: `desktop-editors-module-contract`
**Date**: 2026-10-31
**Feature**: `036-harmonize-vscode-codeserver`

---

## 1. Overview

This contract governs `modules/desktop/editors.nix`, specifying how it consumes the shared VS Code library (`outputs.lib.vscode`) while isolating desktop-only components (`wl-clipboard`, `zed-editor`) to graphical workstations (`desktop-pc`, `macbook-air-m4-15`).

---

## 2. Configuration Requirements

The module MUST configure `programs.vscode` within Home Manager as:

```nix
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = outputs.lib.vscode.extensions pkgs;
      userSettings = outputs.lib.vscode.settings;
    };
  };
}
```

### 2.1 Desktop Isolation Guarantees

- **Wayland Integration**: `pkgs.wl-clipboard` MUST remain scoped to `modules/desktop/editors.nix` (Linux only) and MUST NOT be imported or referenced by `homelab`.
- **Alternative Editors**: `programs.zed-editor` MUST remain in `modules/desktop/editors.nix` and MUST NOT be introduced on headless targets.
- **Zero Duplicate Definitions**: All literal `userSettings` JSON fields and literal `extensions` lists MUST be removed from `modules/desktop/editors.nix`, delegating 100% of common preferences to `outputs.lib.vscode`.

---

## 3. Operational Guarantees

1. **Desktop Parity**: Running VS Code on `desktop-pc` MUST load the exact same theme (`Nord`), typography (`FiraCode Nerd Font`), ruler guides, and extensions as Code Server on `homelab`.
2. **MacBook Compatibility**: `outputs.lib.vscode` MUST evaluate cleanly on macOS (`macbook-air-m4-15`), providing cross-platform parity for macOS Home Manager sessions.
