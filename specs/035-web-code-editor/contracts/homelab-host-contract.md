# Host Integration & Documentation Contract: Homelab Host & README.md

**Feature**: `035-web-code-editor`
**Contract Type**: Host Composition and Living Documentation Interface
**Status**: Active

## 1. Host Composition Contract (`modules/hosts/homelab.nix`)

The `homelab` host definition MUST include `services.code-server` in its `features` attribute:

```nix
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.grub
      core.neovim
      core.preservation

      # Services
      services.caddy
      services.code-server
      services.filebrowser
      services.home-automation
      services.jellyfin
      services.media
      services.n8n
      services.network
      services.nix-ld
      services.opencode
      services.podman
      services.portainer
      services.qbittorrent
      services.sgdf-utils
      services.ssd
      services.ssh
      services.tailscale
      services.uptime-kuma
      services.waha
    ];
```

No inline service logic, port definitions, or proxy directives are permitted in `modules/hosts/homelab.nix` (Constitution Principle II).

---

## 2. Living Documentation Contract (`README.md`)

According to Constitution Principle VI:

- `README.md` MUST be updated within the same branch whenever a service is added.
- The service tables MUST be updated to include `code-server`.
- All operational shell commands MUST provide explicit variants for both **Bash** and **Fish**.

### 2.1 Hosted Services Table Update

The service summary table in `README.md` must include:

| Service | Purpose | Upstream / Package | Storage / Persistence |
|---|---|---|---|
| **Code-Server** | Web-based code editor & remote IDE | Native NixOS (`services.code-server`) | Persistent extensions & settings in `~/.local/share/code-server` and `~/.config/code-server` |

### 2.2 Reverse Proxy Endpoints Table Update

The Caddy endpoints table in `README.md` must include:

| Service | Internal Domain | Target (LAN/Loopback) | Direct LAN Fallback |
|---|---|---|---|
| **Code-Server** | `https://code.homelab.vaylet.fr` | `127.0.0.1:4444` | N/A (loopback bound) |

### 2.3 Operational Instructions Update

A dedicated section detailing how to access and manage the service must be added to `README.md`, including dual-shell commands for testing and deployment:

#### Bash

```bash
# Verify NixOS flake configuration
just check

# Test configuration on homelab without switching boot entry
just test homelab

# Deploy configuration to homelab
just switch homelab
```

#### Fish

```fish
# Verify NixOS flake configuration
just check

# Test configuration on homelab without switching boot entry
just test homelab

# Deploy configuration to homelab
just switch homelab
```
