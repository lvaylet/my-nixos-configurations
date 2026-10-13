# Interface Contract: Host Composition & Isolation

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](../spec.md)

This contract specifies the composition rules for `desktop-pc` and guarantees isolation for headless servers (such as `homelab`).

---

## 1. Desktop Host Composition Contract (`modules/hosts/desktop-pc.nix`)

The `modules/hosts/desktop-pc.nix` file MUST compose `services.bluetooth` into its `features` attribute:

```nix
features = with config.flake.modules; [
  # Base Settings
  core.base
  core.git

  # Desktop & Shell
  desktop.apps
  desktop.audio
  desktop.editors
  desktop.fonts
  desktop.graphics
  desktop.session
  desktop.shell
  desktop.terminal

  # Services
  services.bluetooth
  services.network
  services.nix-ld
  services.podman
  services.printing
  services.ssd
  services.ssh
  services.tailscale
];
```

### Invariants

1. `services.bluetooth` MUST be included alphabetically within the `# Services` section of `features`.
2. `modules/hosts/desktop-pc.nix` MUST NOT declare inline Bluetooth settings, package lists, or options inside `extraModules`.

---

## 2. Server Isolation Contract (`modules/hosts/homelab.nix`)

The `modules/hosts/homelab.nix` host declaration MUST NOT include `services.bluetooth`:

### Invariants

1. `config.hardware.bluetooth.enable` on `homelab` MUST evaluate to `false`.
2. `config.services.blueman.enable` on `homelab` MUST evaluate to `false`.
3. Headless server infrastructure remains unburdened by desktop Bluetooth daemons or user utilities.
