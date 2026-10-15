# Interface Contract: Homelab Host Composition Integration

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](../spec.md)

This contract defines how `modules/hosts/homelab.nix` integrates the `services.waha` feature module.

---

## 1. Host Composition Schema

`modules/hosts/homelab.nix` MUST include `services.waha` in the `features` list of `config.flake.lib.mkHost`:

```nix
    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.preservation

      # Services
      services.caddy
      services.filebrowser
      services.home-automation
      services.jellyfin
      services.media
      services.n8n
      services.network
      services.nix-ld
      services.podman
      services.portainer
      services.qbittorrent
      services.ssd
      services.ssh
      services.tailscale
      services.waha
    ];
```

---

## 2. Invariants & Rules

1. **Zero Inline Service Definitions**: `modules/hosts/homelab.nix` MUST NOT contain any inline container configurations, Caddy virtual hosts, firewall rules, or persistence entries for WAHA.
2. **Dendritic Feature Reference**: The service MUST be referenced solely as `services.waha` through `config.flake.modules`.
3. **Target Isolation**: Other hosts (`desktop-pc`, `iso`) MUST NOT enable `services.waha`.
