# Data Model: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Feature**: `024-fix-filebrowser-quantum`
**Status**: Completed
**Date**: 2026-10-26

---

## 1. Entity Overview

```mermaid
classDiagram
    class FileBrowserContainer {
        +String image
        +List~String~ volumes
        +Map~String,String~ environment
        +List~String~ ports
        +List~String~ extraOptions
        +Map~String,Boolean~ capabilities
    }

    class PreservedFileBrowserDirectories {
        +String configDirectory
        +String cacheDirectory
        +String user
        +String group
        +String mode
    }

    class CaddyVirtualHost {
        +String domain
        +String upstream
    }

    class HostFirewall {
        +List~Int~ allowedTCPPorts
    }

    FileBrowserContainer "1" --> "1" PreservedFileBrowserDirectories : mounts /var/lib/filebrowser:/config
    CaddyVirtualHost "1" --> "1" FileBrowserContainer : reverse_proxy 127.0.0.1:8081
    HostFirewall "1" --> "1" CaddyVirtualHost : allows TCP 443 (blocks TCP 8081)
```

---

## 2. Key Entities & Attributes

### 2.1 FileBrowser Quantum Container (`virtualisation.oci-containers.containers.filebrowser`)

Defined in `modules/services/filebrowser.nix`.

| Attribute | Type | Value | Validation Rule |
| --- | --- | --- | --- |
| `image` | `str` | `"ghcr.io/gtsteffaniak/filebrowser:2-stable"` | Pin to `2-stable` upstream image. |
| `volumes` | `listOf str` | `["/data:/srv" "/var/lib/filebrowser:/config"]` | MUST include both `/data:/srv` and `/var/lib/filebrowser:/config`. |
| `environment.PUID` | `str` | `"992"` | Matches `filebrowser` user UID in `modules/services/media.nix`. |
| `environment.PGID` | `str` | `"995"` | Matches `multimedia` group GID in `modules/services/media.nix`. |
| `environment.UMASK` | `str` | `"0002"` | Grants `rw-rw-r--` (`664`) to created assets in `/data`. |
| `ports` | `listOf str` | `["127.0.0.1:8081:80"]` | MUST bind strictly to `127.0.0.1` so port `8081` is not exposed on `0.0.0.0`. |
| `extraOptions` | `listOf str` | `["--group-add=995"]` | Ensures supplementary access to `multimedia` group. |
| `capabilities.CAP_NET_BIND_SERVICE` | `bool` | `true` | Required by container to bind internal port `80` (`< 1024`). |

### 2.2 Reverse Proxy & Firewall Configuration (`modules/services/filebrowser.nix`)

| Attribute | Type | Value | Validation Rule |
| --- | --- | --- | --- |
| `services.caddy.enable` | `bool` | `true` | Enables Caddy reverse proxy. |
| `services.caddy.virtualHosts."fb.${vars.homelabDomain}".extraConfig` | `str` | `"reverse_proxy 127.0.0.1:8081\n"` | Proxies HTTPS traffic on `fb.<homelabDomain>` to loopback port `8081`. |
| `networking.firewall.allowedTCPPorts` | `listOf port` | `[443]` (port `8081` removed) | Port `8081` MUST NOT be present in the evaluated `allowedTCPPorts` list on `homelab`. |

### 2.3 Preserved Host Directories (`preservation.preserveAt."/persistent".directories`)

| Directory | User | Group | Mode | Purpose |
| --- | --- | --- | --- | --- |
| `/var/lib/filebrowser` | `filebrowser` | `filebrowser` | `"0700"` | Persists FileBrowser Quantum SQLite database, user accounts, and settings under `/persistent/var/lib/filebrowser` and mounts into container at `/config`. |
| `/var/cache/filebrowser` | `filebrowser` | `filebrowser` | `"0700"` | Persists FileBrowser Quantum cache across reboots. |

---

## 3. State Transitions & Invariants

1. **Container Update / Recreation Invariant**: When `podman-filebrowser.service` restarts or pulls a new container image, `/var/lib/filebrowser` on the host remains mounted at `/config` inside the container, preserving the SQLite database and user accounts.
2. **Impermanent Reboot Invariant (`homelab`)**: Across reboots that wipe `/` (`tmpfs`), `preservation` bind-mounts `/persistent/var/lib/filebrowser` to `/var/lib/filebrowser` prior to `podman-filebrowser.service` starting (`after = ["local-fs.target"]`).
3. **Network Isolation Invariant**: Port `8081` is reachable only on `127.0.0.1` by the local Caddy reverse proxy; direct LAN connections to `homelab:8081` are rejected.
