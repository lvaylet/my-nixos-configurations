# Technical Research: Harmonized Visual Studio Code and Code Server Configurations

**Feature Branch**: `036-harmonize-vscode-codeserver`
**Date**: 2026-10-31
**Spec**: [spec.md](spec.md)

---

## 1. Shared Configuration Location & Dendritic Architecture

### Decision
Create a new module `modules/core/vscode.nix` discovered automatically by `import-tree ./modules`. This module contributes shared editor settings and the universal extension list to the flake outputs under `config.flake.lib.vscode`:

```nix
{
  config.flake.lib.vscode = {
    extensions = pkgs: with pkgs.vscode-extensions; [ ... ];
    settings = { ... };
  };
}
```

### Rationale
- **Dendritic Pattern Adherence (Principle II)**: Every `.nix` file under `modules/` is discovered automatically by `flake-parts` via `import-tree ./modules`.
- **Global Availability via `specialArgs`**: The flake composition helper `mkHost` in `modules/core/lib.nix` already passes `outputs = config.flake;` to all NixOS, Darwin, and Home Manager modules via `specialArgs` and `extraSpecialArgs`.
- **Zero Host Plumbery**: Neither `modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`, nor `modules/hosts/macbook-air-m4-15.nix` requires modification to its `features` list. The existing modules `modules/desktop/editors.nix` and `modules/services/code-server.nix` simply consume `outputs.lib.vscode`.
- **Zero Duplication**: Shared settings and extensions are declared exactly once.

### Alternatives Considered
- **Placing definitions in `modules/core/lib.nix`**: Rejected. `modules/core/lib.nix` is dedicated to host constructors (`mkHost`, `mkDarwinHost`) and dendritic module options. Mixing editor user settings into `lib.nix` violates domain separation.
- **Private file with leading underscore (`_vscode-shared.nix`)**: Rejected. Using manual relative `import ../../desktop/_vscode-shared.nix` bypasses dendritic discovery and creates fragile path couplings.
- **Creating a separate host feature module `core.vscode`**: Rejected. Desktop PC already uses `desktop.editors`, and homelab already uses `services.code-server`. Creating an intermediate feature module adds unnecessary ceremony when `outputs.lib.vscode` is directly accessible.

---

## 2. Declarative Extension Packaging for Code Server

### Decision
Use `pkgs.vscode-with-extensions.override` to wrap `code-server` with the shared extension suite:

```nix
services.code-server.package = pkgs.vscode-with-extensions.override {
  vscode = pkgs.code-server;
  vscodeExtensions = outputs.lib.vscode.extensions pkgs;
};
```

### Rationale
- **Native Nixpkgs Support**: `pkgs.vscode-with-extensions` natively supports overriding `vscode = pkgs.code-server`.
- **Hermetic Wrapper**: It generates a wrapper binary in `/nix/store/...-code-server-with-extensions-4.134.0/bin/code-server` that automatically appends `--extensions-dir /nix/store/.../share/vscode/extensions "$@"` to the execution line.
- **Fast and Fully Cached**: All extensions (`nord-visual-studio-code`, `vscode-markdownlint`, `nix-ide`, `nix`, `alejandra`, `even-better-toml`) evaluate and build cleanly in the Nix sandbox without network access at runtime.
- **Parity**: Identical extension derivations are used by Home Manager's `programs.vscode` on `desktop-pc`.

### Alternatives Considered
- **Imperative installation via `systemd.services.code-server.preStart`**: Rejected. Running `code-server --install-extension <id>` during boot violates declarative principles (Principle I), slows service startup, and fails when offline or behind restricted proxies.
- **Manual tmpfiles symlinking of extensions directory**: Rejected. Brittle, reinventing what nixpkgs `vscode-with-extensions` already handles cleanly.

---

## 3. Declarative Settings Deployment on Homelab (Without Home Manager)

### Decision
Generate an immutable `settings.json` derivation using Nix's built-in JSON generator `(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings`, and symlink it into Code Server's user profile directories using `systemd.tmpfiles.rules` with `L+` (force link) semantics:

```nix
systemd.tmpfiles.rules = [
  "d /home/${vars.userName}/.local/share/code-server/User 0755 ${vars.userName} users -"
  "L+ /home/${vars.userName}/.local/share/code-server/User/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
  "d /home/${vars.userName}/.config/code-server 0755 ${vars.userName} users -"
  "L+ /home/${vars.userName}/.config/code-server/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
];
```

### Rationale
- **Code Server Path Specifications**: In code-server, user settings are read from `$user-data-dir/User/settings.json`. By default on Linux, `user-data-dir` is `~/.local/share/code-server`. Creating `~/.local/share/code-server/User/settings.json` provides direct settings discovery by the VS Code web core.
- **Symlink Parity with Home Manager**: On `desktop-pc`, Home Manager creates a symlink from `~/.config/Code/User/settings.json` to the Nix store. Using `systemd.tmpfiles.rules` achieves the exact same declarative, immutable behavior on `homelab` without requiring Home Manager.
- **Generation Upgrades**: `L+` semantics ensure that when `outputs.lib.vscode.settings` is updated in the repository and activated with `nh os switch`, the symlink is atomically updated to point to the new store path.

### Alternatives Considered
- **Command-line arguments (`--vscode-option`)**: Rejected. Code-server's `--vscode-option` flag cannot cleanly model deeply nested JSON structures (e.g. `nix.serverSettings.nixd.formatting.command` or `[nix]` editor overrides).
- **Mutable file creation**: Rejected. Creating a mutable copy on boot allows configuration drift and violates Declarative Configuration (Principle I).

---

## 4. Developer Toolchain Parity

### Decision
Add `alejandra` and `nixd` to `services.code-server.extraPackages` in `modules/services/code-server.nix`:

```nix
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
```

### Rationale
- The shared VS Code settings configure `nixd` as `nix.serverPath` and `alejandra` as `formatting.command`.
- Without `nixd` and `alejandra` in the service's `PATH`, the Nix IDE extension reports missing LSP server errors when opening `.nix` files on `homelab`.
- Adding them to `extraPackages` guarantees that Code Server's integrated terminal and extension host find them immediately.

### Alternatives Considered
- **Relying on system-wide `environment.systemPackages`**: Rejected. Providing packages explicitly in `services.code-server.extraPackages` keeps the service self-contained and hermetic.

---

## 5. State Preservation & Reboot Continuity

### Decision
Retain existing state preservation rules in `modules/services/code-server.nix`:
```nix
preservation.preserveAt."/persistent".users.${vars.userName}.directories = lib.mkIf config.services.caddy.enable [
  ".local/share/code-server"
  ".config/code-server"
];
```

### Rationale
- `homelab` runs with an ephemeral root on `tmpfs`.
- Mutable runtime data (workspace history, search caches, session state) is preserved across reboots in `/persistent/home/laurent`.
- Declarative symlinks created by `systemd.tmpfiles.rules` (`L+`) take precedence and point to the immutable Nix store, ensuring settings cannot be accidentally corrupted or drifted by runtime sessions.
