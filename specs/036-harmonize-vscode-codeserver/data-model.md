# Data Model & System Entities: Harmonized Visual Studio Code and Code Server Configurations

**Feature**: `036-harmonize-vscode-codeserver`
**Date**: 2026-10-31
**Status**: Completed

---

## 1. Architectural Entity Overview

```text
+---------------------------------------------------------------------------------------------------+
|                                     modules/core/vscode.nix                                       |
|                                                                                                   |
|  config.flake.lib.vscode:                                                                         |
|    - settings: attrset (theme, typography, format-on-save, rulers, diff, git, [nix], LSP)        |
|    - extensions: pkgs -> list (github-actions, github-pull-requests, nord, markdownlint, nix-ide, nix, alejandra, even-better-toml) |
+---------------------------------------------------------------------------------------------------+
                                         |                         |
               (specialArgs.outputs.lib.vscode)     (specialArgs.outputs.lib.vscode)
                                         |                         |
                                         v                         v
+--------------------------------------------------+  +---------------------------------------------+
|         Host: desktop-pc (NixOS + HM)            |  |              Host: homelab (NixOS)          |
|         modules/desktop/editors.nix              |  |         modules/services/code-server.nix    |
|                                                  |  |                                             |
|  programs.vscode.profiles.default:               |  |  services.code-server:                      |
|    - extensions = outputs.lib.vscode.extensions  |  |    - package = vscode-with-extensions       |
|    - userSettings = outputs.lib.vscode.settings  |  |        (with outputs.lib.vscode.extensions)|
|                                                  |  |    - extraPackages = [ ... nixd alejandra ] |
|  Home Manager Symlink:                           |  |  systemd.tmpfiles.rules:                    |
|    ~/.config/Code/User/settings.json             |  |    L+ ~/.local/share/code-server/User/      |
|      -> /nix/store/...-settings.json             |  |         settings.json -> /nix/store/...     |
|                                                  |  |    L+ ~/.config/code-server/settings.json|
|  Desktop-Only Tools:                             |  |  Persistent Layer:                          |
|    - wl-clipboard (Wayland clipboard)            |  |    /persistent/home/laurent/                |
|    - programs.zed-editor                         |  |      - .local/share/code-server             |
|                                                  |  |      - .config/code-server                  |
+--------------------------------------------------+  +---------------------------------------------+
```

---

## 2. Declarative Entities

### 2.1 Shared VS Code Library (`modules/core/vscode.nix`)

Represents the single source of truth for all common editor preferences and extensions.

| Attribute | Type | Description |
|---|---|---|
| `config.flake.lib.vscode.extensions` | `function (pkgs -> list of package)` | Curated universal extensions: `github.vscode-github-actions`, `github.vscode-pull-request-github`, `nord-visual-studio-code`, `vscode-markdownlint`, `nix-ide`, `nix`, `alejandra`, `even-better-toml`. |
| `config.flake.lib.vscode.settings` | `attribute set` | Universal editor settings JSON specification. |

#### Settings Key Specification

| Category | Key | Value | Description |
|---|---|---|---|
| **Visual / Theme** | `workbench.colorTheme` | `"Nord"` | Consistent dark theme |
| **Typography** | `editor.fontFamily` | `"FiraCode Nerd Font"` | Primary editor typography |
| | `editor.fontLigatures` | `true` | Font ligature support |
| | `editor.fontSize` | `12` | Default font size in pt |
| | `chat.editor.fontFamily` | `"FiraCode Nerd Font"` | Chat font family |
| | `debug.console.fontFamily` | `"FiraCode Nerd Font"` | Debug console font family |
| | `scm.inputFontFamily` | `"FiraCode Nerd Font"` | Git commit input font family |
| | `terminal.integrated.fontFamily` | `"FiraCode Nerd Font"` | Integrated terminal font |
| | `terminal.integrated.fontLigatures.enabled` | `true` | Terminal font ligatures |
| | `terminal.integrated.fontSize` | `12` | Terminal font size |
| | `terminal.integrated.lineHeight` | `1.2` | Terminal line height |
| **Editor Behavior** | `editor.lineNumbers` | `"relative"` | Relative line numbering for navigation |
| | `editor.formatOnSave` | `true` | Automatically format code on save |
| | `editor.rulers` | `[ 80 88 100 120 ]` | Column guideline rulers |
| | `diffEditor.codeLens` | `true` | Diff code lens |
| | `diffEditor.hideUnchangedRegions.enabled` | `true` | Collapses unchanged diff regions |
| | `diffEditor.ignoreTrimWhitespace` | `false` | Highlight whitespace diffs |
| | `explorer.confirmDelete` | `false` | Bypasses GUI file delete prompt |
| | `explorer.confirmDragAndDrop` | `false` | Bypasses drag-and-drop prompt |
| | `files.autoSave` | `"afterDelay"` | Auto-saves buffer modifications |
| | `files.insertFinalNewline` | `true` | Enforces POSIX final newline |
| | `files.trimFinalNewlines` | `true` | Trims redundant trailing newlines |
| | `window.menuBarVisibility` | `"toggle"` | Minimalist menu bar visibility |
| | `window.zoomLevel` | `1` | Zoom scaling |
| **Git Integration** | `git.autofetch` | `true` | Automatically fetches remote changes |
| | `git.confirmSync` | `false` | Skips confirmation when syncing git |
| | `git.suggestSmartCommit` | `false` | Disables automated commit suggestion prompts |
| **File Associations**| `files.associations."*.bu"` | `"yaml"` | Butane configuration files |
| | `files.associations."*.container"` | `"ini"` | Quadlet container unit files |
| | `files.associations."*.ign"` | `"json"` | Ignition configuration files |
| **Nix Language** | `[nix]."editor.tabSize"` | `2` | 2-space indentation for Nix |
| | `[nix]."editor.formatOnPaste"` | `true` | Auto-format Nix code on paste |
| | `[nix]."editor.formatOnSave"` | `true` | Auto-format Nix code on save |
| | `[nix]."editor.formatOnType"` | `false` | Avoid disruptive typing formatting |
| | `nix.enableLanguageServer` | `true` | Enable Nix language server |
| | `nix.serverPath` | `"nixd"` | Use nixd LSP binary |
| | `nix.serverSettings.nixd.formatting.command` | `[ "alejandra" ]` | Enforce alejandra as Nix formatter |

---

### 2.2 Desktop Consumer Entity (`modules/desktop/editors.nix`)

Consumes `outputs.lib.vscode` via Home Manager.

| Attribute | Value | Description |
|---|---|---|
| `programs.vscode.enable` | `true` | Activates VS Code in Home Manager. |
| `programs.vscode.profiles.default.extensions` | `outputs.lib.vscode.extensions pkgs` | Declarative shared extension derivations. |
| `programs.vscode.profiles.default.userSettings` | `outputs.lib.vscode.settings` | Declarative shared settings map. |
| `home.packages` | `[ pkgs.wl-clipboard ]` (Linux only) | Retains desktop-only clipboard tooling. |
| `programs.zed-editor` | Configured | Retains desktop-only Zed editor setup. |

---

### 2.3 Server Consumer Entity (`modules/services/code-server.nix`)

Consumes `outputs.lib.vscode` via native NixOS service and tmpfiles rules.

| Attribute | Value | Description |
|---|---|---|
| `services.code-server.package` | `pkgs.vscode-with-extensions.override { vscode = pkgs.code-server; vscodeExtensions = outputs.lib.vscode.extensions pkgs; }` | Wrapped code-server derivation bundling all shared extensions. |
| `services.code-server.extraPackages` | `with pkgs; [ alejandra bash coreutils direnv git just nh nix nixd nixos-rebuild ripgrep ]` | Runtime toolchain ensuring `nixd` and `alejandra` are in PATH for LSP diagnostics and formatting. |
| `systemd.tmpfiles.rules` | Rules symlinking `/home/laurent/.local/share/code-server/User/settings.json` and `/home/laurent/.config/code-server/settings.json` to Nix store | Declarative, immutable settings file deployment. |
| `preservation.preserveAt."/persistent"` | Preserves `.local/share/code-server` and `.config/code-server` | Survives reboots on impermanent root tmpfs. |

---

## 3. Validation Rules

- **Zero Inline Duplication**: `modules/desktop/editors.nix` and `modules/services/code-server.nix` MUST NOT declare duplicate `userSettings` key-value pairs or extension packages.
- **Home Manager Isolation**: `homelab` MUST NOT import or enable Home Manager (`enableHomeManager = false` strictly enforced).
- **Desktop Isolation**: `wl-clipboard` and `zed-editor` MUST NOT be installed or exposed on `homelab`.
- **Atomic Symlink Upgrades**: All `systemd.tmpfiles.rules` targeting `settings.json` MUST use `L+` to force link replacement upon new NixOS generation activation.
