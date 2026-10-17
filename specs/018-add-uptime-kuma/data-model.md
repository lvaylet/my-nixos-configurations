# Data Model: Uptime Kuma Monitoring Service for Homelab

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, storage layout, relationships, and invariants for the Uptime Kuma monitoring service on `homelab`.

---

## 1. Entities & Configuration Schemas

### Entity 1: Uptime Kuma Service Feature Module (`modules/services/uptime-kuma.nix`)

Represents the dendritic capability module encapsulating the native NixOS Uptime Kuma service, static system user/group, systemd mount ordering, Caddy reverse proxy virtual host, firewall rules, and declarative state preservation.

| Category | Option / Attribute | Value / Schema | Purpose |
| --- | --- | --- | --- |
| **Dendritic Identification** | `flake.modules.services.uptime-kuma.nixos` | NixOS Module function `({ config, lib, vars, ... }: { ... })` | Auto-discovered feature module via `import-tree` (`FR-009`) |
| **Native Service** | `services.uptime-kuma.enable` | `true` | Enables Uptime Kuma monitoring service (`FR-001`) |
| | `services.uptime-kuma.settings.HOST` | `"127.0.0.1"` | Binds strictly to local loopback interface (`FR-003`) |
| | `services.uptime-kuma.settings.PORT` | `"3002"` | Non-conflicting local TCP port (`FR-003`) |
| **Container Socket** | `virtualisation.podman.dockerSocket.enable` | `true` | Symlinks `/run/docker.sock` (`/var/run/docker.sock`) to `/run/podman/podman.sock` (`FR-006`) |
| **System User & Group** | `users.users.uptime-kuma` | `{ isSystemUser = true; group = "uptime-kuma"; extraGroups = [ "podman" ]; }` | Static system user in `podman` group for `/persistent` and Podman socket access |
| | `users.groups.uptime-kuma` | `{}` | Dedicated system group for `/var/lib/uptime-kuma` |
| **Systemd Lifecycle** | `systemd.services.uptime-kuma.after` | `[ "local-fs.target" "podman.socket" ]` | Waits for persistent mounts and Podman socket (`FR-009`) |
| | `systemd.services.uptime-kuma.requires` | `[ "podman.socket" ]` | Ensures `podman.socket` is active before service mount namespace setup |
| | `systemd.services.uptime-kuma.serviceConfig.DynamicUser` | `lib.mkForce false` | Uses static user instead of `/var/lib/private` symlink indirection |
| | `systemd.services.uptime-kuma.serviceConfig.PrivateUsers` | `lib.mkForce false` | Preserves host `podman` group mapping instead of squashing to `nogroup` |
| | `systemd.services.uptime-kuma.serviceConfig.User` | `"uptime-kuma"` | Runs service as `uptime-kuma` user |
| | `systemd.services.uptime-kuma.serviceConfig.Group` | `"uptime-kuma"` | Runs service as `uptime-kuma` group |
| | `systemd.services.uptime-kuma.serviceConfig.SupplementaryGroups` | `[ "podman" ]` | Grants access to `/run/podman/podman.sock` (`0660 root:podman`) |
| | `systemd.services.uptime-kuma.serviceConfig.ReadWritePaths` | `[ "/run/podman" ]` | Allows UNIX socket `connect(2)` under `ProtectSystem = "strict"` |
| **Reverse Proxy** | `services.caddy.enable` | `true` | Enables centralized Caddy reverse proxy |
| | `services.caddy.virtualHosts."uptime.${vars.homelabDomain}".extraConfig` | `reverse_proxy 127.0.0.1:3002` | Routes `https://uptime.homelab.vaylet.fr` (HTTP + WebSocket) to Uptime Kuma (`FR-002`, `FR-004`) |
| **Firewall** | `networking.firewall.allowedTCPPorts` | `[ 443 ]` | Allows inbound HTTPS traffic to Caddy |
| **Preservation** | `preservation.preserveAt."/persistent".directories` | `[ { directory = "/var/lib/uptime-kuma"; user = "uptime-kuma"; group = "uptime-kuma"; mode = "0750"; } ]` | Persists SQLite database, monitors, credentials, and metrics across reboots (`FR-006`) |

#### Relationships

- **Depends on**: `modules/services/caddy.nix` for Cloudflare DNS-01 ACME TLS termination on `*.homelab.vaylet.fr`.
- **Depends on**: `modules/core/preservation.nix` for `/persistent` bind-mount persistence across ephemeral root reboots.
- **Depends on**: `modules/core/vars.nix` for `vars.homelabDomain` (`"homelab.vaylet.fr"`).
- **Monitors**: Local and proxied homelab services (`Home Assistant`, `n8n`, `WAHA`, `FileBrowser Quantum`, `Portainer CE`, `Jellyfin`, `qBittorrent`) and external endpoints.
- **Composed into**: `modules/hosts/homelab.nix` via `config.flake.modules.services.uptime-kuma`.

---

### Entity 2: Homelab Host Composition (`modules/hosts/homelab.nix`)

Represents the target host configuration assembling hardware and feature modules.

| Attribute | Type | Current State | Target State | Validation Rule |
| --- | --- | --- | --- | --- |
| `features` | List of Modules | Enables `services.caddy`, `services.n8n`, `services.tailscale`, `services.waha`, etc. | Adds `services.uptime-kuma` in alphabetical order between `services.tailscale` and `services.waha` | Must only reference `config.flake.modules.*` |
| `extraModules` | List of Modules | Host-specific boot/SSH/hostname settings | Unchanged | Zero inline service definitions |

---

### Entity 3: Persistent Storage Layout (`/persistent/var/lib/uptime-kuma`)

Represents the persistent directory structure on the `homelab` host.

```text
/persistent/var/lib/uptime-kuma/
├── kuma.db                    # Embedded SQLite database (users, monitors, notifications, status pages, heartbeats)
├── kuma.db-shm                # SQLite WAL shared-memory file
├── kuma.db-wal                # SQLite Write-Ahead Log file
├── upload/                    # Custom status page icons and uploaded assets
└── screenshots/               # Browser/monitor diagnostic artifacts (if applicable)
```

#### Field Specifications & Permissions

| Path | Type | Owner | Group | Mode | Persistence & Security Requirement |
| --- | --- | --- | --- | --- | --- |
| `/var/lib/uptime-kuma` | Directory | `uptime-kuma` | `uptime-kuma` | `0750` | Preserved at `/persistent/var/lib/uptime-kuma` via bind mount |
| `/var/lib/uptime-kuma/kuma.db` | File | `uptime-kuma` | `uptime-kuma` | `0640` | Created and managed by Uptime Kuma on first startup |

---

### Entity 4: Service Monitor Lifecycle State

Represents the runtime state machine of a monitor configured inside Uptime Kuma:

```text
PENDING ──(check succeeds)──────────────────────────────► UP
   │                                                      │ ▲
   └──(check fails < maxretries)──► PENDING               │ │
   │                                  │                   │ │ (recovery check succeeds + recovery notification)
   └──(check fails >= maxretries)─────┴──(down alert)──► DOWN
                                                          │
   ┌──────────────────(manual pause / window)─────────────┴─┐
   ▼                                                        ▼
MAINTENANCE / PAUSED ──(resume / window ends)──────────► PENDING
```

---

## 2. Invariants & Business Rules

1. **Loopback Binding Invariant**: `services.uptime-kuma.settings.HOST` MUST be `"127.0.0.1"` and `PORT` MUST be `"3002"`; port `3002` MUST NOT be opened in `networking.firewall.allowedTCPPorts`.
2. **Port Non-Collision Invariant**: Port `3002` avoids conflicts with `adguardhome` (`3000`), `waha` (`3001`), `n8n` (`5679`), `portainer` (`8000`, `9443`), `qbittorrent` (`8080`), `filebrowser` (`8081`), `jellyfin` (`8096`), and `home-automation` (`8123`).
3. **State Preservation Invariant**: `/var/lib/uptime-kuma` MUST be registered in `preservation.preserveAt."/persistent".directories` with `user = "uptime-kuma"`, `group = "uptime-kuma"`, and `mode = "0750"` whenever `config.services.uptime-kuma.enable` is `true`, and `DynamicUser` MUST be forced to `false` so systemd does not conflict with the bind-mounted directory.
4. **Mount Order Invariant**: `systemd.services.uptime-kuma` MUST include `after = [ "local-fs.target" ]` to prevent initializing a blank SQLite database in ephemeral `tmpfs` before `/persistent` is mounted.
5. **Target Isolation Invariant**: Enabling `services.uptime-kuma` on `homelab` MUST NOT affect `desktop-pc` or `iso` evaluations.
