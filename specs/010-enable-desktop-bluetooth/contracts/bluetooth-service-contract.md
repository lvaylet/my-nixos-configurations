# Interface Contract: Bluetooth Service Feature Module

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](../spec.md)

This contract defines the schema, types, configuration values, and evaluation invariants for the Bluetooth service module at `modules/services/bluetooth.nix`.

---

## 1. Nix Module Declaration Contract (`modules/services/bluetooth.nix`)

The module MUST expose `flake.modules.services.bluetooth` using the dendritic structure:

```nix
{
  flake.modules.services.bluetooth = {
    nixos = {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };

      services.blueman.enable = true;
    };
  };
}
```

### Module Invariants

1. **Module Identification**: Exported under `flake.modules.services.bluetooth`.
2. **Top-Level Discovery**: Discoverable automatically via `import-tree ./modules` without manual imports.
3. **No Hardcoded Machine Names**: Module MUST NOT reference specific hostnames (e.g. `desktop-pc`).
4. **Hermetic & Pure**: Depends strictly on NixOS options without impure file reads or imperative commands.

---

## 2. NixOS Configuration Attribute Invariants

When evaluated within a target NixOS system configuration with `services.bluetooth` enabled:

| NixOS Option | Type | Required Value | Purpose |
| --- | --- | --- | --- |
| `config.hardware.bluetooth.enable` | `bool` | `true` | Installs BlueZ, enables `bluetooth.service`, and registers D-Bus interface |
| `config.hardware.bluetooth.powerOnBoot` | `bool` | `true` | Automatically powers on the default adapter during boot |
| `config.hardware.bluetooth.settings.General.Experimental` | `bool` | `true` | Enables GATT battery reporting and experimental BlueZ features |
| `config.hardware.bluetooth.settings.Policy.AutoEnable` | `bool` | `true` | Automatically powers on detected and hot-plugged Bluetooth controllers |
| `config.services.blueman.enable` | `bool` | `true` | Installs Blueman desktop manager, applet, D-Bus service, and polkit rules |

---

## 3. Evaluation Diagnostics Contract

Evaluating the host configuration:

- `nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.enable` MUST evaluate to `true`.
- `nix eval .#nixosConfigurations.desktop-pc.config.services.blueman.enable` MUST evaluate to `true`.
- `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` MUST succeed with 0 evaluation warnings or errors.
- `just check` (`nix flake check`) MUST succeed with exit code 0.
