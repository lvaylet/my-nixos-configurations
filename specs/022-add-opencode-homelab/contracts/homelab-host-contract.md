# Interface Contract: Homelab Host Integration & Documentation Parity

**Feature Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25

## 1. Host Composition Contract (`modules/hosts/homelab.nix`)

In adherence to Constitution Principle II (Dendritic Modularity):

- `modules/hosts/homelab.nix` MUST only compose hardware and feature modules.
- `services.opencode` MUST be added to the `features` list in `modules/hosts/homelab.nix`.
- No inline service logic or daemon configuration may be introduced directly into `homelab.nix`.

```nix
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
      services.opencode       # Added: OpenCode v2 service + CLI + Caddy reverse proxy
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

## 2. Living Documentation & Parity Contract (`README.md`)

In adherence to Constitution Principle VI (Living Documentation & Dual-Shell Parity):

- `README.md` MUST be updated within the same branch to include OpenCode v2 in:
  1. The Architecture Overview / Features summary.
  2. The Hosted Services table (with service name, purpose, and port `4096`).
  3. The Reverse Proxy Endpoints table (specifying `https://opencode.homelab.vaylet.fr`).
- All operational commands, verification instructions, and password retrieval commands MUST be provided with explicit **Bash** and **Fish** code blocks whenever syntax differs.

### Example Contract for Dual-Shell Operational Instructions

#### Bash

```bash
# Retrieve the generated OpenCode server password on homelab
ssh laurent@homelab "sudo cat /var/lib/opencode/opencode.env"
```

#### Fish

```fish
# Retrieve the generated OpenCode server password on homelab
ssh laurent@homelab "sudo cat /var/lib/opencode/opencode.env"
```
