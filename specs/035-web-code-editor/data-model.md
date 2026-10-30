# Data Model & System Entities: Remote Web Code Editor on Homelab

**Feature**: `035-web-code-editor`
**Date**: 2026-10-30
**Status**: Completed

## 1. Entity Overview

The Web Code Editor capability introduces declarative entities within the NixOS system configuration and runtime state layers.

```text
+-----------------------------------------------------------------------------------+
|                              Host: homelab (NixOS)                                |
|                                                                                   |
|  +-----------------------------+         +-------------------------------------+  |
|  |     Caddy Virtual Host      |         |      Systemd Service Unit           |  |
|  | code.homelab.vaylet.fr:443  |-------> |         code-server.service         |  |
|  | (Cloudflare DNS-01 ACME)    |         |  (User: laurent, Port: 4444)        |  |
|  +-----------------------------+         +-------------------------------------+  |
|                 |                                           |                     |
|                 v                                           v                     |
|  +-----------------------------+         +-------------------------------------+  |
|  |      Tailscale Overlay      |         |         Editor Workspace            |  |
|  |   100.127.199.88:443        |         |          /home/laurent              |  |
|  |  (Private CGNAT network)    |         | (Workspace repos, dotfiles, config) |  |
|  +-----------------------------+         +-------------------------------------+  |
|                                                             |                     |
|                                                             v                     |
|                                          +-------------------------------------+  |
|                                          |     Preservation Bindmounts         |  |
|                                          |   /persistent/home/laurent/         |  |
|                                          |   - .local/share/code-server        |  |
|                                          |   - .config/code-server             |  |
|                                          +-------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Declarative Nix Entities

### 2.1 Code-Server Service Specification (`modules/services/code-server.nix`)

Represents the declarative configuration for the web editor daemon.

| Attribute | Type | Default / Assigned Value | Description |
|---|---|---|---|
| `enable` | `bool` | `true` | Enables the `code-server` systemd service. |
| `user` | `string` | `vars.userName` (`"laurent"`) | Unprivileged execution user. |
| `group` | `string` | `"users"` | Primary group for the service. |
| `auth` | `enum` | `"none"` | Authentication method; delegated to Tailscale. |
| `host` | `string` | `"127.0.0.1"` | Loopback interface binding for security. |
| `port` | `int` | `4444` | Local port dedicated to `code-server`. |
| `extraArguments` | `list of str` | `[ "/home/${vars.userName}" ]` | Initial workspace folder opened on startup. |
| `disableTelemetry` | `bool` | `true` | Disables telemetry reporting to upstream servers. |
| `disableUpdateCheck` | `bool` | `true` | Disables update checks (updates managed via Nix flake). |
| `extraPackages` | `list of package` | `[ bash coreutils direnv git just nh nix nixos-rebuild ripgrep ]` | Tooling available in the integrated terminal `PATH`. |

### 2.2 Reverse Proxy Virtual Host (`services.caddy.virtualHosts`)

Represents the ingress routing and TLS termination rule.

| Attribute | Value | Description |
|---|---|---|
| Domain Key | `"code.${vars.homelabDomain}"` (`code.homelab.vaylet.fr`) | Ingress FQDN for the web editor. |
| Target Upstream | `127.0.0.1:4444` | Local loopback destination for the reverse proxy. |
| TLS Challenge | Cloudflare DNS-01 (`acme_dns cloudflare`) | Inherited from centralized Caddy configuration. |
| WebSocket Support | Automatic | Native Caddy reverse proxy streaming support for VS Code WebSocket channels. |

### 2.3 Ephemeral State Preservation (`preservation.preserveAt."/persistent"`)

Represents directories retained across tmpfs impermanence wipes on `homelab`.

| Target Path | Persistent Storage Path | Owner:Group | Mode | Content / Purpose |
|---|---|---|---|---|
| `/home/laurent/.local/share/code-server` | `/persistent/home/laurent/.local/share/code-server` | `laurent:users` | `0755` | Installed VS Code extensions, cached extension metadata, session backups. |
| `/home/laurent/.config/code-server` | `/persistent/home/laurent/.config/code-server` | `laurent:users` | `0755` | User settings, keybindings, workspace layout configs. |

---

## 3. Runtime State & Lifecycle Invariants

1. **In-Memory Volatility**: The root filesystem `/` on `homelab` is a volatile `tmpfs`. Any files written by `code-server` outside of `/persistent` or `/home/laurent/workspace` (already preserved) will be cleared upon reboot.
2. **Permission Consistency**: All files created or modified by `code-server` are owned by `laurent:users`.
3. **Port Isolation**: Port `4444` must never be exposed directly on WAN or non-loopback network interfaces. Only Caddy connects to `127.0.0.1:4444`.
4. **Tailnet Restriction**: `code.homelab.vaylet.fr` DNS points exclusively to `100.127.199.88`. Requests from outside the Tailscale private network cannot reach Caddy.
5. **Process Supervision**: Systemd manages `code-server.service` with automatic restart on failure (`Restart = "on-failure"`, `RestartSec = 5`).
