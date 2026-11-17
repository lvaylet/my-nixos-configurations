# Research: OpenCode 2 CLI Configuration Migration

**Feature**: `042-migrate-opencode-cli-config`
**Date**: 2026-11-17

## Context & Objectives

During NixOS system activation (`just switch` or `nix eval`), Home Manager emits an evaluation warning:
```text
evaluation warning: laurent profile: programs.opencode.tui is ignored by OpenCode 2.

                    OpenCode 2 replaced tui.json with a single global cli.json. Move
                    terminal client settings to programs.opencode.cli. When
                    programs.opencode.mutableSettings is enabled, OPENCODE_TUI_CONFIG is
                    ignored as well.

                    OpenCode 2 only migrates an existing tui.json when cli.json does not
                    exist. See: https://opencode.ai/v2/docs/cli/config
```

The objective is to eliminate this warning across all repository targets while preserving the configured Nord theme and terminal experience for OpenCode 2 across both desktop and headless server environments (`desktop-pc`, `homelab`, `macbook-air-m4-15`).

---

## Decisions & Rationale

### 1. Configuration Option Migration in Home Manager

- **Decision**: Replace `programs.opencode.tui` with `programs.opencode.cli` in `modules/services/opencode.nix`.
- **Rationale**:
  - Upstream Home Manager's `programs.opencode` module differentiates OpenCode 1 from OpenCode 2.
  - When `programs.opencode.package` is OpenCode 2 (this repository pins `v2.1.4`), `programs.opencode.tui` triggers an evaluation warning because OpenCode 2 no longer reads `tui.json`.
  - Setting `programs.opencode.cli` populates `~/.config/opencode/cli.json` (or `home-manager-cli.json` when `mutableSettings` is true) and leaves `tui` empty, completely silencing the evaluation warning.
- **Alternatives Considered**:
  - *Keep `programs.opencode.tui`*: Rejected because it generates noisy evaluation warnings and is deprecated upstream.
  - *Move settings to `programs.opencode.settings`*: Rejected because `programs.opencode.settings` writes `opencode.json` (server and project configuration) and explicitly warns if terminal/TUI keys are placed there.

### 2. Schema Structure for OpenCode 2 CLI Configuration

- **Decision**: Set `cli.theme = { name = "nord"; };`.
- **Rationale**:
  - The OpenCode 2 CLI schema (`https://opencode.ai/v2/cli.json`) defines `theme` as an object:
    ```json
    "theme": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "mode": { "enum": ["system", "dark", "light"] }
      },
      "additionalProperties": false
    }
    ```
  - In OpenCode 1, `tui.json` accepted `theme = "nord"`.
  - In OpenCode 2, `cli.json` requires an object `{ "name": "nord" }`. Optional `mode` defaults to following terminal appearance if omitted.
  - Passing `{ name = "nord"; }` adheres to the schema and enables schema validation.
- **Alternatives Considered**:
  - *`cli.theme = "nord"`*: Rejected because it does not match the object schema in `https://opencode.ai/v2/cli.json` and would fail schema validation.
  - *`cli.theme = { name = "nord"; mode = "dark"; }`*: Rejected because allowing `mode` to follow the terminal default (`system`) is more flexible while `name = "nord"` sets the palette.

### 3. Parity for Headless Server Host (`homelab`)

- **Decision**: Update `modules/services/opencode.nix` in the `nixos` block to declaratively link `cli.json` alongside `opencode.json` using `systemd.tmpfiles.rules`.
- **Rationale**:
  - On `homelab`, Home Manager is disabled (`enableHomeManager = false` per Constitution Principle II).
  - OpenCode interactive terminal sessions on `homelab` (via `ssh homelab` -> `opencode`) read `~/.config/opencode/cli.json` for theme and client behavior.
  - Generating and linking `opencode-cli.json` ensures full visual and functional parity across all environments.
- **Alternatives Considered**:
  - *Only modify `homeManager`*: Rejected because `homelab` interactive terminal sessions would run with unconfigured default themes.

### 4. Coexistence with `opencode.json`

- **Decision**: Keep `opencode.json` for general/server settings, and use `cli.json` for terminal client settings.
- **Rationale**:
  - OpenCode 2 cleanly splits configuration:
    - `opencode.json`: Server, model, MCP servers, and provider settings.
    - `cli.json`: Visual styling, theme, keybinds, diff viewer, and tab bar.
  - On `desktop-pc`, `homeManager` manages `cli.json`, while `nixos` tmpfiles manages `opencode.json`.
  - On `homelab`, both `opencode.json` and `cli.json` are managed via tmpfiles.
- **Alternatives Considered**:
  - *Consolidate everything into `opencode.json`*: Impossible because OpenCode 2 explicitly ignores terminal client settings in `opencode.json`.

---

## Verification Strategy

1. **Static Analysis & Evaluation**:
   - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` must evaluate with 0 warnings.
   - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath` must evaluate with 0 warnings.
   - `nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath` must evaluate with 0 warnings.
2. **Quality Gates**:
   - `just check` (`nix flake check`) must succeed with exit code 0.
   - `just fmt` (`nix fmt .`) must format cleanly with Alejandra.
   - `just lint` (`statix check` and `deadnix`) must report zero issues.
