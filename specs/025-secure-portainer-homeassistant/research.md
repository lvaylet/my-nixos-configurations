# Technical Research: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Feature**: `025-secure-portainer-homeassistant`
**Status**: Completed
**Date**: 2026-10-26

---

## 1. Portainer Podman Socket Access Without `--privileged`

### Context

In `modules/services/portainer.nix`, the Portainer container was configured with:

```nix
extraOptions = [
  "--privileged" # Recommended so Portainer can run low-level operations on container engine.
];
```

Upstream Portainer install guides for Podman on RHEL/CentOS/Fedora include `--privileged` because SELinux mandatory access control (`container_t`) blocks containers from connecting to `/var/run/podman/podman.sock` unless SELinux labels are disabled (`--security-opt label=disable` or `--privileged`).

### Decision

Remove `extraOptions = ["--privileged"];` completely from `virtualisation.oci-containers.containers.portainer` in `modules/services/portainer.nix`, leaving only the UNIX socket bind mount `/var/run/podman/podman.sock:/var/run/docker.sock` and persistent volume `/var/lib/portainer:/data`.

### Rationale

- **No SELinux Enforcement on NixOS**: NixOS does not enable SELinux by default, so standard DAC permissions apply to `/var/run/podman/podman.sock`.
- **Rootful Podman Socket Ownership**: `virtualisation.oci-containers.backend = "podman"` runs `podman-portainer.service` in rootful mode, where UID `0` inside the container maps to UID `0` on the host and has direct read/write access to `/var/run/podman/podman.sock` (`root:podman`, mode `0660`).
- **Least-Privilege Hardening**: Removing `--privileged` restores default OCI container isolation (dropped kernel capabilities such as `CAP_SYS_ADMIN`, `CAP_SYS_MODULE`, masked `/proc` and `/sys` paths, and blocked direct access to host block devices).

### Alternatives Considered

- **`--security-opt=no-new-privileges` or keeping `--privileged`**:
  - *Rejected*: Keeping `--privileged` disables all container confinement unnecessarily; omitting `extraOptions` (defaulting to `[]`) matches the declarative simplicity of `modules/services/waha.nix` and `modules/services/n8n.nix`.

---

## 2. Portainer Loopback Binding (`127.0.0.1:9443:9443`) and Firewall Hardening

### Context

Currently, `modules/services/portainer.nix` publishes `"8000:8000"` and `"9443:9443"` on all host interfaces (`0.0.0.0`) and opens `networking.firewall.allowedTCPPorts = [ 8000 9443 ]`. However:

- Port `8000` is the optional TCP tunnel server for remote Portainer Edge Agents, which is unused on this single-node homelab.
- Caddy already reverse-proxies `portainer.${vars.homelabDomain}` to `https://127.0.0.1:9443` over port `443`.

### Decision

1. Restrict `virtualisation.oci-containers.containers.portainer.ports` to `["127.0.0.1:9443:9443"]` (removing `"8000:8000"`).
2. Remove `networking.firewall.allowedTCPPorts = [ 8000 9443 ];` from `modules/services/portainer.nix` (relying on `modules/services/caddy.nix` which already opens TCP port `443` whenever `services.caddy.enable = true`).

### Rationale

- **Eliminates Self-Signed Certificate & Management Plane Exposure on LAN**: Portainer's built-in HTTPS listener on port `9443` uses a self-signed certificate and exposes the administrative login directly on the LAN. Binding to `127.0.0.1:9443` ensures all external access goes through Caddy (`https://portainer.homelab.vaylet.fr`) with valid ACME certificates on the private Tailscale network.
- **Closes Unused Attack Surface**: Removing port `8000` eliminates an unused Edge Agent listener.

### Alternatives Considered

- **Binding Portainer HTTP port `9000` (`127.0.0.1:9000:9000`) instead of `9443`**:
  - *Rejected*: Issue #32 specifically prescribes `ports = ["127.0.0.1:9443:9443"]` to preserve compatibility with the existing Caddy `reverse_proxy https://127.0.0.1:9443` configuration without requiring `portainer` CLI flags (`--http-enabled`).

---

## 3. Home Assistant Firewall Hardening (`modules/services/home-automation.nix`)

### Context

In `modules/services/home-automation.nix`:

- The container runs with `--network=host` so mDNS, SSDP, UPnP, and Zeroconf broadcasts reach local smart-home devices.
- `networking.firewall.allowedTCPPorts = [ 443 8123 ];` was configured in `modules/services/home-automation.nix`.
- Port `443` is redundant with `modules/services/caddy.nix` (`networking.firewall.allowedTCPPorts = lib.mkIf config.services.caddy.enable [ 443 ];`).
- Port `8123` exposes Home Assistant's unencrypted HTTP server to any device on the local network, whereas Caddy already serves `https://ha.${vars.homelabDomain}` by proxying to `127.0.0.1:8123`.

### Decision

1. Remove `networking.firewall.allowedTCPPorts = [ 443 8123 ];` from `modules/services/home-automation.nix`.
2. Retain `--network=host` in `virtualisation.oci-containers.containers.homeassistant.extraOptions` for local device discovery.
3. Document SSH local port forwarding (`ssh -L 8123:127.0.0.1:8123 laurent@homelab`) in `README.md` (with both Bash and Fish variants) for the one-time initial UI reverse proxy trust setup on a fresh Home Assistant installation.

### Rationale

- **Trusted Loopback vs External Interfaces**: NixOS's firewall (`networking.firewall.enable = true`) unconditionally permits traffic on `lo` (`127.0.0.1` / `::1`), so Caddy (`reverse_proxy 127.0.0.1:8123`) continues to reach Home Assistant even though `--network=host` is used and `8123` is removed from `allowedTCPPorts`.
- **Blocks Unencrypted LAN HTTP Traffic**: External devices on the LAN can no longer connect to `http://homelab:8123` in cleartext; all browser and mobile app connections must use `https://ha.homelab.vaylet.fr` over HTTPS.
- **Preserves Smart-Home Discovery**: Keeping `--network=host` allows Home Assistant to initiate outbound connections to LAN IoT devices and participate in multicast discovery while inbound TCP connections to `8123` from non-loopback interfaces are dropped by the firewall.

### Alternatives Considered

- **Removing `--network=host` and using `-p 127.0.0.1:8123:8123`**:
  - *Rejected*: Upstream Home Assistant documentation strongly requires `--network=host` for mDNS/Zeroconf/UPnP auto-discovery of local smart-home integrations. Blocking inbound TCP `8123` via the NixOS host firewall achieves loopback-only HTTP access without breaking local device discovery.
