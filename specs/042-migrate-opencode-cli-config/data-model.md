# Data Model: OpenCode 2 CLI Configuration

**Feature**: `042-migrate-opencode-cli-config`
**Date**: 2026-11-17

## Entities & Configuration Schemas

### 1. OpenCode CLI Configuration (`cli.json`)

Represents the declarative client settings file read by OpenCode 2 interactive terminal sessions at `$XDG_CONFIG_HOME/opencode/cli.json`.

| Field | Type | Required | Description | Value / Constraint |
|---|---|---|---|---|
| `$schema` | string (URI) | Optional | Schema validation URI | `https://opencode.ai/v2/cli.json` |
| `theme` | object | Optional | Color theme configuration | Object matching `ThemeConfig` |

#### `ThemeConfig` Object

| Field | Type | Required | Description | Value / Constraint |
|---|---|---|---|---|
| `name` | string | Yes | Name of the active theme | `"nord"` |
| `mode` | string | No | Mode lock (`system`, `dark`, `light`) | Defaults to terminal mode if omitted |

### 2. Home Manager Module Options (`programs.opencode`)

Represents the Home Manager option tree evaluated during NixOS host build.

| Option | Type | Default | Description | Updated Value |
|---|---|---|---|---|
| `programs.opencode.enable` | boolean | `false` | Enables OpenCode module | `true` |
| `programs.opencode.package` | package | `pkgs.opencode` | OpenCode derivation | Pinned `inputs.opencode` (v2.1.4) |
| `programs.opencode.extraPackages` | list of package | `[]` | Additional CLI utilities in PATH | `[ pkgs.nodejs pkgs.uv ]` |
| `programs.opencode.tui` | JSON attrset | `{}` | Legacy OpenCode 1 TUI options | `{}` (unspecified / default) |
| `programs.opencode.cli` | JSON attrset | `{}` | OpenCode 2 CLI options | `{ theme = { name = "nord"; }; }` |

### 3. Non-Home-Manager Declarative Symlinks (`homelab`)

Represents systemd-tmpfiles rules deploying declarative configuration on hosts without Home Manager.

| Path | Target | Rule Type | Owner | Group | Mode |
|---|---|---|---|---|---|
| `/home/laurent/.config/opencode/opencode.json` | Generated `opencode.json` derivation | `L+` | `laurent` | `users` | `-` |
| `/home/laurent/.config/opencode/cli.json` | Generated `opencode-cli.json` derivation | `L+` | `laurent` | `users` | `-` |
| `/home/laurent/.config/opencode/skills` | Generated `opencode-skills` derivation | `L+` | `laurent` | `users` | `-` |

---

## Configuration Flow & Lifecycle

```text
Nix Evaluation (desktop-pc)
  └── Home Manager (programs.opencode)
        ├── package = OpenCode 2.1.4
        ├── tui = {} (empty -> no warning)
        └── cli = { theme = { name = "nord"; }; }
              └── writes ~/.config/opencode/cli.json
                    ├── "$schema": "https://opencode.ai/v2/cli.json"
                    └── "theme": { "name": "nord" }

Nix Evaluation (homelab)
  └── NixOS Module (modules/services/opencode.nix)
        └── systemd.tmpfiles.rules
              └── links ~/.config/opencode/cli.json -> /nix/store/...-opencode-cli.json
```
