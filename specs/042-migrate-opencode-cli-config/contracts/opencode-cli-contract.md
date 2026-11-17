# Interface Contract: OpenCode 2 CLI Configuration

**Contract ID**: `opencode-cli-config-contract`
**Date**: 2026-11-17
**Feature**: `042-migrate-opencode-cli-config`

---

## 1. Overview

This contract specifies the structure and guarantees for OpenCode 2 terminal client configuration across all target machines in `my-nixos-configurations`. It ensures complete elimination of evaluation warnings while preserving the Nord visual theme across both Home Manager and systemd-tmpfiles deployment vectors.

---

## 2. Declarative Module Contract (`modules/services/opencode.nix`)

### 2.1 Home Manager Profile (`homeManager`)

The Home Manager module MUST declare OpenCode client options via `programs.opencode.cli` and MUST NOT declare any options under `programs.opencode.tui`.

```nix
programs.opencode = {
  enable = true;
  package = opencodePackage;
  extraPackages = with pkgs; [
    nodejs
    uv
  ];
  cli = {
    theme = {
      name = "nord";
    };
  };
};
```

**Guarantees**:

1. `programs.opencode.tui` remains an empty attribute set `{}`.
2. Zero evaluation warnings are emitted during `nix eval` or `nh os switch` / `just switch`.
3. Home Manager writes `$HOME/.config/opencode/cli.json` containing valid JSON with schema `https://opencode.ai/v2/cli.json`.

---

### 2.2 Systemd Tmpfiles Profile (`nixos` for headless server)

For hosts without Home Manager (`homelab`), `systemd.tmpfiles.rules` MUST provide `cli.json` alongside `opencode.json` when Home Manager is not present:

```nix
let
  opencodeCliConfigFile = pkgs.writeText "opencode-cli.json" (builtins.toJSON {
    "$schema" = "https://opencode.ai/v2/cli.json";
    theme = {
      name = "nord";
    };
  });
in {
  systemd.tmpfiles.rules = [
    # ...
    "L+ /home/${vars.userName}/.config/opencode/opencode.json - - - - ${opencodeConfigFile}"
  ] ++ lib.optionals (!(config ? home-manager)) [
    "L+ /home/${vars.userName}/.config/opencode/cli.json - - - - ${opencodeCliConfigFile}"
    "L+ /home/${vars.userName}/.config/opencode/skills - - - - ${opencodeSkillsDir}"
  ];
}
```

**Guarantees**:

1. Interactive shell sessions on `homelab` (`ssh homelab` -> `opencode`) find `cli.json` with Nord theme configured.
2. No conflict with Home Manager on `desktop-pc`, because the tmpfiles rule for `cli.json` is conditional on `!(config ? home-manager)`.

---

## 3. JSON Output Format (`cli.json`)

The generated `$HOME/.config/opencode/cli.json` file MUST conform to the OpenCode 2 CLI schema:

```json
{
  "$schema": "https://opencode.ai/v2/cli.json",
  "theme": {
    "name": "nord"
  }
}
```
