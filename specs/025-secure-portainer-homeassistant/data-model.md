# Data Model: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Feature**: `025-secure-portainer-homeassistant`
**Status**: Completed
**Date**: 2026-10-26

---

## 1. Entity Overview

```mermaid
classDiagram
    class PortainerContainer {
        +String image
        +List~String~ volumes
        +List~String~ ports
        +List~String~ extraOptions
    }

    class HomeAssistantContainer {
        +String image
        +List~String~ volumes
        +Map~String,String~ environment
        +List~String~ extraOptions
    }

    class CaddyReverseProxy {
        +Boolean enable
        +String portainerVhost
        +String homeAssistantVhost
    }

    class HostFirewall {
        +Boolean enable
        +List~Int~ allowedTCPPorts
    }

    CaddyReverseProxy "1" --> "1" PortainerContainer : reverse_proxy https://127.0.0.1:9443
    CaddyReverseProxy "1" --> "1" HomeAssistantContainer : reverse_proxy 127.0.0.1:8123
    HostFirewall "1" --> "1" CaddyReverseProxy : allows TCP 443 (blocks TCP 8000, 9443, 8123)
```

---

## 2. Key Entities & Attributes

### 2.1 Portainer OCI Container (`virtualisation.oci-containers.containers.portainer`)

Defined in `modules/services/portainer.nix`.

| Attribute | Type | Value | Validation Rule |
| --- | --- | --- | --- |
| `image` | `str` | `"docker.io/portainer/portainer-ce:lts"` | Pin to `lts` upstream image. |
| `volumes` | `listOf str` | `["/var/run/podman/podman.sock:/var/run/docker.sock" "/var/lib/portainer:/data"]` | Mounts Podman socket and persistent `/var/lib/portainer` data directory. |
| `ports` | `listOf str` | `["127.0.0.1:9443:9443"]` | MUST bind strictly to `127.0.0.1:9443:9443` and MUST NOT include port `8000`. |
| `extraOptions` | `listOf str` | `[]` (default) | MUST NOT include `"--privileged"`. |

### 2.2 Home Assistant OCI Container (`virtualisation.oci-containers.containers.homeassistant`)

Defined in `modules/services/home-automation.nix`.

| Attribute | Type | Value | Validation Rule |
| --- | --- | --- | --- |
| `image` | `str` | `"ghcr.io/home-assistant/home-assistant:2026.10"` | Pinned `2026.10` upstream image. |
| `volumes` | `listOf str` | `["/var/lib/home-assistant:/config" "/run/dbus:/run/dbus:ro"]` | Mounts persistent `/var/lib/home-assistant` config directory and read-only D-Bus socket. |
| `environment.TZ` | `str` | `"Europe/Paris"` | Configures container timezone. |
| `extraOptions` | `listOf str` | `["--network=host"]` | Retains host network namespace for mDNS/UPnP local discovery. |

### 2.3 Reverse Proxy & Firewall Configuration (`modules/services/portainer.nix`, `modules/services/home-automation.nix`, `modules/services/caddy.nix`)

| Attribute | Type | Value | Validation Rule |
| --- | --- | --- | --- |
| `services.caddy.virtualHosts."portainer.${vars.homelabDomain}".extraConfig` | `str` | `"reverse_proxy https://127.0.0.1:9443 {\n  transport http {\n    tls_insecure_skip_verify\n  }\n}\n"` | Proxies HTTPS traffic on `portainer.<homelabDomain>` to loopback port `9443`. |
| `services.caddy.virtualHosts."ha.${vars.homelabDomain}".extraConfig` | `str` | `"reverse_proxy 127.0.0.1:8123\n"` | Proxies HTTPS traffic on `ha.<homelabDomain>` to loopback port `8123`. |
| `networking.firewall.allowedTCPPorts` | `listOf port` | Contains `443` (from `caddy.nix`); excludes `8000`, `9443`, and `8123` | Ports `8000`, `9443`, and `8123` MUST NOT be present in the evaluated `allowedTCPPorts` list on `homelab`. |

---

## 3. State Transitions & Invariants

1. **Portainer Least-Privilege Invariant**: Portainer runs without `--privileged` (`extraOptions == []`) and accesses the Podman API strictly via `/var/run/podman/podman.sock`.
2. **Portainer Loopback Invariant**: Portainer's HTTPS server listens only on `127.0.0.1:9443`; port `8000` is not bound, and neither `8000` nor `9443` is opened in the host firewall.
3. **Home Assistant Firewall Invariant**: Home Assistant listens in the host network namespace (`--network=host`), where loopback connections from Caddy (`127.0.0.1:8123`) are permitted on `lo` while external LAN connections to TCP port `8123` are blocked by `networking.firewall`.
