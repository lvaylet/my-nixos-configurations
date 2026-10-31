# Interface Contract: Shared VS Code Library (`modules/core/vscode.nix`)

**Contract ID**: `shared-vscode-library-contract`
**Date**: 2026-10-31
**Feature**: `036-harmonize-vscode-codeserver`

---

## 1. Overview

This contract governs the interface provided by `modules/core/vscode.nix` to the flake outputs under `config.flake.lib.vscode`. It serves as the single source of truth for both desktop Visual Studio Code and remote Code Server.

---

## 2. Flake Output Specification

The module MUST declare `config.flake.lib.vscode` with the following members:

```nix
{
  config.flake.lib.vscode = {
    extensions = pkgs: [ ... ];
    settings = { ... };
  };
}
```

### 2.1 `extensions` Function Contract

- **Signature**: `pkgs: [ derivation ]`
- **Argument**: `pkgs` (Nixpkgs package set for the target system architecture).
- **Return Value**: List of package derivations from `pkgs.vscode-extensions`.
- **Mandatory Extensions**:
  1. `pkgs.vscode-extensions.github.vscode-github-actions`
  2. `pkgs.vscode-extensions.github.vscode-pull-request-github`
  3. `pkgs.vscode-extensions.arcticicestudio.nord-visual-studio-code`
  4. `pkgs.vscode-extensions.davidanson.vscode-markdownlint`
  5. `pkgs.vscode-extensions.jnoortheen.nix-ide`
  6. `pkgs.vscode-extensions.bbenoist.nix`
  7. `pkgs.vscode-extensions.kamadorueda.alejandra`
  8. `pkgs.vscode-extensions.tamasfe.even-better-toml`

### 2.2 `settings` Attribute Set Contract

- **Format**: Attribute set directly serializable to JSON via `pkgs.formats.json` or consumable by Home Manager's `programs.vscode.profiles.<profile>.userSettings`.
- **Mandatory Keys & Expected Types**:
  - `workbench.colorTheme`: `"Nord"`
  - `editor.fontFamily`: `"FiraCode Nerd Font"`
  - `editor.fontLigatures`: `true`
  - `editor.lineNumbers`: `"relative"`
  - `editor.fontSize`: `12`
  - `editor.formatOnSave`: `true`
  - `editor.rulers`: `[ 80 88 100 120 ]`
  - `chat.editor.fontFamily`: `"FiraCode Nerd Font"`
  - `debug.console.fontFamily`: `"FiraCode Nerd Font"`
  - `scm.inputFontFamily`: `"FiraCode Nerd Font"`
  - `diffEditor.codeLens`: `true`
  - `diffEditor.hideUnchangedRegions.enabled`: `true`
  - `diffEditor.ignoreTrimWhitespace`: `false`
  - `explorer.confirmDelete`: `false`
  - `explorer.confirmDragAndDrop`: `false`
  - `files.associations`: Attrset (`*.bu` -> yaml, `*.container` -> ini, `*.ign` -> json)
  - `files.autoSave`: `"afterDelay"`
  - `files.insertFinalNewline`: `true`
  - `files.trimFinalNewlines`: `true`
  - `git.autofetch`: `true`
  - `git.confirmSync`: `false`
  - `git.suggestSmartCommit`: `false`
  - `terminal.integrated.fontFamily`: `"FiraCode Nerd Font"`
  - `terminal.integrated.fontLigatures.enabled`: `true`
  - `terminal.integrated.fontSize`: `12`
  - `terminal.integrated.lineHeight`: `1.2`
  - `window.menuBarVisibility`: `"toggle"`
  - `window.zoomLevel`: `1`
  - `[nix]`: Attrset (`editor.tabSize` = 2, `editor.formatOnPaste` = true, `editor.formatOnSave` = true, `editor.formatOnType` = false)
  - `nix.enableLanguageServer`: `true`
  - `nix.serverPath`: `"nixd"`
  - `nix.serverSettings.nixd.formatting.command`: `[ "alejandra" ]`

---

## 3. Guarantees

1. **Pure Evaluation**: `config.flake.lib.vscode` MUST evaluate purely without impure references or side effects.
2. **Dendritic Discovery**: Discovered automatically via `import-tree ./modules` without manual import in `flake.nix`.
3. **Immutability**: The configuration definition is declarative and version-controlled.
