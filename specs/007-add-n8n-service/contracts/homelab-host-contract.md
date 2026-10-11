# Interface Contract: Homelab Host Composition Integration

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](../spec.md)

This contract defines how `modules/hosts/homelab.nix` integrates the `services.n8n` feature module.

---

## 1. Host Composition Schema

`modules/hosts/homelab.nix` MUST include `services.n8n` in the `features` list of `config.flake.lib.mkHost`:

```nix
{
  config,
  lib,
  ...
}: {
  flake.nixosConfigurations.homelab = config.flake.lib.mkHost {
    system = "x86_64-linux";
    enableHomeManager = false;

    # Hardware
    # ---
    hardware = ./_hardware/homelab.nix;

    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.preservation

      # Services
      services.network
      services.ssh
      services.podman
      services.media
      services.filebrowser
      services.home-automation
      services.portainer
      services.jellyfin
      services.qbittorrent
      services.nix-ld
      services.ssd
      services.n8n # Added workflow automation service
    ];

    extraModules = [
      # ... existing host overrides ...
    ];
  };
}
```

---

## 2. Invariants & Rules

1. **Zero Inline Service Definitions**: `modules/hosts/homelab.nix` MUST NOT contain any inline container configurations, firewall rules, or persistence entries for n8n.
2. **Dendritic Feature Reference**: The service MUST be referenced solely as `services.n8n` through `config.flake.modules`.
3. **Target Isolation**: Other hosts (`desktop-pc`, `iso`) MUST NOT enable `services.n8n` unless explicitly requested.
