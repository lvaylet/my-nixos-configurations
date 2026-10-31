# Service Contract: Code-Server Service (`modules/services/code-server.nix`)

**Contract ID**: `code-server-service-contract`
**Date**: 2026-10-31
**Feature**: `036-harmonize-vscode-codeserver`

---

## 1. Overview

This contract specifies the operational and declarative requirements for `modules/services/code-server.nix` when consuming the shared VS Code library (`outputs.lib.vscode`).

---

## 2. Configuration Requirements

The module MUST configure `services.code-server` with:

```nix
{
  services.code-server = {
    enable = true;
    user = vars.userName;
    group = "users";
    auth = "none";
    host = "127.0.0.1";
    port = 4444;
    disableTelemetry = true;
    disableUpdateCheck = true;
    extraArguments = [ "/home/${vars.userName}" ];
    package = pkgs.vscode-with-extensions.override {
      vscode = pkgs.code-server;
      vscodeExtensions = outputs.lib.vscode.extensions pkgs;
    };
    extraPackages = with pkgs; [
      alejandra
      bash
      coreutils
      direnv
      git
      just
      nh
      nix
      nixd
      nixos-rebuild
      ripgrep
    ];
  };
}
```

### 2.1 Declarative Settings Symlinks (`systemd.tmpfiles.rules`)

The module MUST declare tmpfiles rules to link `outputs.lib.vscode.settings` as an immutable JSON file into the user profile:

```nix
systemd.tmpfiles.rules = [
  "d /home/${vars.userName}/.local/share/code-server/User 0755 ${vars.userName} users -"
  "L+ /home/${vars.userName}/.local/share/code-server/User/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
  "d /home/${vars.userName}/.config/code-server 0755 ${vars.userName} users -"
  "L+ /home/${vars.userName}/.config/code-server/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
];
```

### 2.2 Preservation Rules

The module MUST retain ephemeral persistence under `/persistent`:

```nix
preservation.preserveAt."/persistent".users.${vars.userName}.directories = lib.mkIf config.services.caddy.enable [
  ".local/share/code-server"
  ".config/code-server"
];
```

---

## 3. Operational Guarantees

1. **Extension Availability**: All 6 shared extensions MUST be pre-installed in the store wrapper and available immediately upon browser connection without downloading from open-vsx or VS Code marketplace.
2. **Settings Enforcement**: `settings.json` MUST point to the Nix store with `L+` force replacement, guaranteeing settings consistency across system upgrades.
3. **LSP Diagnostics & Formatting**: `nixd` and `alejandra` MUST be available in the process environment of Code Server, enabling zero-configuration Nix LSP and formatting on save.
