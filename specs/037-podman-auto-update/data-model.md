# Data Model: Automated Container Image Updates via Podman

**Feature**: `037-podman-auto-update`
**Date**: 2026-11-01

## 1. Systemd Timer Entity: `podman-auto-update.timer`

Controls the recurring schedule for polling remote registries and applying updates to eligible running containers.

| Property | Type | Value | Description |
|---|---|---|---|
| `Unit` | string | `podman-auto-update.service` | Target oneshot service executed by this timer. |
| `OnCalendar` | string | `"daily"` | Calendar recurrence; triggers once every 24 hours at midnight. |
| `Persistent` | boolean | `true` | Catches up missed runs if the host was offline or sleeping. |
| `RandomizedDelaySec` | string / integer | `"900"` (15 min) | Spreads registry polling to avoid spike requests on network connectivity. |
| `WantedBy` | list of strings | `[ "timers.target" ]` | Enables the timer at system initialization. |

---

## 2. Systemd Service Entity: `podman-auto-update.service`

Encapsulates the oneshot execution of the Podman auto-update engine and subsequent post-update garbage collection.

| Property | Type | Value | Description |
|---|---|---|---|
| `Type` | string | `"oneshot"` | Runs to completion and exits. |
| `ExecStart` | path / command | `${pkgs.podman}/bin/podman auto-update` | Discovers labeled containers, pulls changed image digests, and restarts services. |
| `ExecStartPost` | path / command | `${pkgs.podman}/bin/podman image prune -f` | Prunes dangling/untagged image layers left behind after updates. |
| `Wants` | list of strings | `[ "network-online.target" ]` | Ensures network interfaces are online before attempting registry queries. |
| `After` | list of strings | `[ "network-online.target" ]` | Orders execution after network connectivity is established. |

---

## 3. Container Auto-Update Policy Entity

Declared within `extraOptions` of each `virtualisation.oci-containers.containers.<name>` block.

### Attributes

| Attribute | Type | Format / Allowed Values | Description |
|---|---|---|---|
| `label` | string | `io.containers.autoupdate=registry` | Instructs Podman to compare local manifest digest with remote registry manifest. |
| `imageTag` | string | Tracking tag (e.g. `:lts`, `:latest`, `:stable`) | Tag monitored for upstream digest changes. |
| `serviceUnit` | string | `podman-<name>.service` | Systemd service unit restarted upon image digest transition. |

### Container Inventory & Update Policy Matrix

| Container Name | Module | Image | Auto-Update Label | Associated Systemd Service |
|---|---|---|---|---|
| `portainer` | `modules/services/portainer.nix` | `docker.io/portainer/portainer-ce:lts` | `io.containers.autoupdate=registry` | `podman-portainer.service` |
| `homeassistant` | `modules/services/home-automation.nix` | `ghcr.io/home-assistant/home-assistant:2026.10` | `io.containers.autoupdate=registry` | `podman-homeassistant.service` |
| `filebrowser` | `modules/services/filebrowser.nix` | `ghcr.io/gtsteffaniak/filebrowser:2-stable` | `io.containers.autoupdate=registry` | `podman-filebrowser.service` |
| `waha` | `modules/services/waha.nix` | `docker.io/devlikeapro/waha:latest` | `io.containers.autoupdate=registry` | `podman-waha.service` |
| `n8n` | `modules/services/n8n.nix` | `docker.io/n8nio/n8n:latest` | `io.containers.autoupdate=registry` | `podman-n8n.service` |
| `n8n-runners` | `modules/services/n8n.nix` | `docker.io/n8nio/runners:latest` | `io.containers.autoupdate=registry` | `podman-n8n-runners.service` |

---

## 4. State Transitions

```text
[ Container Running on Digest D1 ]
               │
               ▼
   Daily Timer / Manual Run
               │
               ▼
  Query Registry for Tag Digest
               │
      ┌────────┴────────┐
      ▼                 ▼
[ Digest == D1 ]   [ Digest == D2 (New) ]
      │                 │
      ▼                 ▼
  No Action        Pull Image Layers
  (Zero Downtime)       │
                        ▼
                   Stop Container
                        │
                        ▼
                  Start Container on D2
                        │
                        ▼
                  Prune Dangling D1 Layers
```
