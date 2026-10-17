# Interface Contract: Homelab Host Composition & Documentation Integration

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](../spec.md)

This contract defines how `modules/hosts/homelab.nix` integrates the `services.uptime-kuma` feature module and how `README.md` is updated to maintain constitutional parity.

---

## 1. Host Composition Schema (`modules/hosts/homelab.nix`)

`modules/hosts/homelab.nix` MUST include `services.uptime-kuma` in alphabetical order in the `features` list of `config.flake.lib.mkHost`:

```nix
    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.neovim
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
      services.uptime-kuma
      services.waha
    ];
```

---

## 2. Documentation Contract (`README.md`)

In accordance with Constitution Principle VI (*Living Documentation & Dual-Shell Parity*), `README.md` MUST be updated within the same branch:

1. **Architecture Tree (`modules/services/`)**: Include `Uptime Kuma` in the services domain description.
2. **Homelab Hosted Services Table**:
   - **Service**: `**Uptime Kuma**`
   - **Type**: `Native Service`
   - **Network / Ports**: `` `443` (HTTPS via Caddy) ``
   - **Storage / Data**: `` `/var/lib/uptime-kuma` ``
   - **Description**: `Self-hosted monitoring tool for tracking service availability, response latency, and TLS certificate expiration with real-time alerts.`
3. **Reverse Proxy & Secure HTTPS Access Table**:
   - **Service**: `**Uptime Kuma**`
   - **Subdomain / External URL**: `` `https://uptime.homelab.vaylet.fr` ``
   - **Upstream Target**: `` `127.0.0.1:3002` ``
   - **LAN Direct URL**: `N/A (loopback bound)`

---

## 3. Invariants & Rules

1. **Zero Inline Service Definitions**: `modules/hosts/homelab.nix` MUST NOT contain any inline service configurations, Caddy virtual hosts, firewall rules, or persistence entries for Uptime Kuma.
2. **Dendritic Feature Reference**: The service MUST be referenced solely as `services.uptime-kuma` through `config.flake.modules`.
3. **Target Isolation**: Other hosts (`desktop-pc`, `iso`) MUST NOT enable `services.uptime-kuma`.
