# Technical Research: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Feature**: `024-fix-filebrowser-quantum`
**Status**: Completed
**Date**: 2026-10-26

---

## 1. Persistent Configuration Volume Mount (`/var/lib/filebrowser:/config`)

### Context

In `modules/services/filebrowser.nix`, `preservation.preserveAt."/persistent".directories` already preserves `/var/lib/filebrowser` (owned by `filebrowser:filebrowser`, UID `992`, mode `0700`) and `/var/cache/filebrowser`. However, in `virtualisation.oci-containers.containers.filebrowser`, the volume mount `"/var/lib/filebrowser:/config"` was left commented out (`# "/var/lib/filebrowser:/config" # TODO Is that relevant/required?`). As a result, FileBrowser Quantum (`ghcr.io/gtsteffaniak/filebrowser:2-stable`) writes its SQLite database and configuration inside the container's ephemeral rootfs, losing all user accounts and settings whenever the container is recreated or updated.

### Decision

Uncomment and enable `"/var/lib/filebrowser:/config"` in `virtualisation.oci-containers.containers.filebrowser.volumes`:

```nix
volumes = [
  "/data:/srv"
  "/var/lib/filebrowser:/config"
];
```

### Rationale

- **Upstream Container Convention**: The `ghcr.io/gtsteffaniak/filebrowser:2-stable` OCI image uses `/config` as its default working/configuration directory for storing `database.db` (or `filebrowser.db`) and `config.yaml` when `/config` is mounted as a volume.
- **UID/GID Alignment**: `modules/services/media.nix` defines the static `filebrowser` system user with `uid = 992` and group `filebrowser`, while `preservation` creates `/persistent/var/lib/filebrowser` owned by `filebrowser:filebrowser` (`0700`). Because the container runs with `PUID = "992"`, the container process has full read/write permissions to `/config` on the bind-mounted directory.
- **Impermanence Survival**: Mounting `/var/lib/filebrowser:/config` bridges the container's internal `/config` state to `/persistent/var/lib/filebrowser`, ensuring survival across both Podman container recreations and `homelab` ephemeral `tmpfs` reboots.

### Alternatives Considered

- **Named Podman volume (`filebrowser_config:/config`)**:
  - *Rejected*: Named volumes reside inside `/var/lib/containers/storage/volumes/` and obscure direct host inspection and explicit directory ownership rules already configured in `preservation.preserveAt."/persistent".directories`.

---

## 2. Loopback-Only Port Binding (`127.0.0.1:8081:80`) and Firewall Hardening

### Context

Currently, `modules/services/filebrowser.nix` configures:

```nix
ports = [
  "8081:80" # host:container
];
networking.firewall.allowedTCPPorts = [
  8081
];
```

By omitting the host bind IP in `ports`, Podman binds TCP port `8081` to `0.0.0.0` (all interfaces), and `networking.firewall.allowedTCPPorts = [ 8081 ]` opens it to the entire local network over unencrypted HTTP—bypassing Caddy's HTTPS termination (`https://fb.${vars.homelabDomain}`).

### Decision

1. Bind the container port strictly to `127.0.0.1`:
   ```nix
   ports = [
     # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
     "127.0.0.1:8081:80"
   ];
   ```
2. Replace `8081` with `443` in `networking.firewall.allowedTCPPorts` (matching the exact convention in `modules/services/n8n.nix`, `modules/services/waha.nix`, and `modules/services/uptime-kuma.nix`):
   ```nix
   # Open HTTPS port in firewall.
   networking.firewall.allowedTCPPorts = [
     443
   ];
   ```

### Rationale

- **Defense in Depth**: Binding to `127.0.0.1:8081:80` ensures the socket itself never listens on external interfaces, while removing `8081` from `networking.firewall.allowedTCPPorts` ensures `nftables`/`iptables` does not advertise or permit incoming traffic on port `8081`.
- **Codebase Consistency**: `modules/services/n8n.nix` (`127.0.0.1:5679:5678`), `modules/services/waha.nix` (`127.0.0.1:3001:3000`), and `modules/services/uptime-kuma.nix` (`127.0.0.1:3002`) all bind strictly to `127.0.0.1` and declare `networking.firewall.allowedTCPPorts = [ 443 ];`.

### Alternatives Considered

- **Omitting `networking.firewall.allowedTCPPorts` entirely in `filebrowser.nix`**:
  - *Evaluated*: While `modules/services/caddy.nix` also opens `443`, keeping `networking.firewall.allowedTCPPorts = [ 443 ];` in `filebrowser.nix` (or omitting `8081`) is idempotent in NixOS list merging and stays 100% consistent with `n8n.nix`, `waha.nix`, and `uptime-kuma.nix`. Either way, `8081` is completely absent from `config.networking.firewall.allowedTCPPorts`.
