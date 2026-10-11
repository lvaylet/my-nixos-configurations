# Technical Research: n8n Workflow Automation Service for Homelab

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives evaluated for deploying n8n on the `homelab` host within the dendritic NixOS configuration.

---

## 1. Deployment Runtime: Native NixOS Service vs OCI Container (Podman)

### Decision
Deploy n8n as an OCI container managed by systemd via Podman (`virtualisation.oci-containers.containers.n8n`) using the official image `docker.io/n8nio/n8n:latest`.

```nix
# modules/services/n8n.nix
virtualisation.oci-containers.containers.n8n = {
  image = "docker.io/n8nio/n8n:latest";
  volumes = [
    "/var/lib/n8n:/home/node/.n8n"
  ];
  environment = {
    TZ = "Europe/Paris";
    GENERIC_TIMEZONE = "Europe/Paris";
    N8N_PORT = "5678";
    N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
  };
  ports = [
    "5678:5678"
  ];
  user = "1000:1000";
};
```

### Rationale
- **Binary Cache & Licensing Constraint**: The native package `pkgs.n8n` in Nixpkgs carries an unfree license (`sustainableUse`). The central NixOS binary cache (`cache.nixos.org` / Hydra) does not build or cache unfree packages. Using the native package would require local source compilation with `pnpm` on every version bump. On the low-power Intel N150 processor (Alder Lake-N, 4 efficiency cores), compiling the extensive Node.js/pnpm dependency tree of n8n consumes substantial memory and CPU time, risking build failures and out-of-memory errors.
- **Architectural Consistency**: The `homelab` host already standardizes on Podman for standalone upstream web applications (Home Assistant in `home-automation.nix`, Portainer in `portainer.nix`, and Filebrowser in `filebrowser.nix`). Podman is already configured in `modules/services/podman.nix` with rootful container management, DNS resolution, and automatic image pruning.
- **Upstream Alignment**: The official n8n Docker image is the upstream-recommended self-hosted deployment method, guaranteeing bundled node extensions, security patches, and tested runtime environments.
- **Systemd Supervision**: Podman integrates natively with systemd via `systemd.services."podman-n8n"`, ensuring automatic restarts on failure and clean lifecycle handling.

### Alternatives Considered
- **Native NixOS service (`services.n8n`)**: Evaluated. While supported in recent Nixpkgs versions, it suffers from unfree license cache absence, lengthy local compilation times, and configuration drift with rapid upstream release cycles. Rejected in favor of containerized execution.
- **Docker Engine (`virtualisation.docker`)**: The repository already uses Podman (`virtualisation.podman.enable = true` with `dockerCompat = true`), avoiding redundant container daemon overhead.

---

## 2. Storage & State Persistence Architecture

### Decision
Store all n8n workflows, credentials, settings, and execution history in `/var/lib/n8n`, mounted into the container at `/home/node/.n8n`. Colocate state preservation in `modules/services/n8n.nix` targeting `/persistent/var/lib/n8n`:

```nix
preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? n8n) [
  {
    directory = "/var/lib/n8n";
    user = "1000";
    group = "1000";
    mode = "0750";
  }
];
```

Ensure systemd startup sequencing waits for local filesystems:

```nix
systemd.services."podman-n8n".after = [
  "local-fs.target"
];
```

### Rationale
- **Impermanence Protection**: `homelab` boots with an ephemeral tmpfs root. Without explicit preservation rules, all files in `/var/lib/n8n` would be wiped upon host reboot. Declaring preservation ensures bind mounts to `/persistent` retain all user automations.
- **Database Engine Choice (Embedded SQLite)**: n8n uses embedded SQLite by default stored in the configuration directory. For single-host homelab automation workloads (typically hundreds to low thousands of executions per day), SQLite is zero-overhead, highly performant, and does not require managing a separate database daemon or container network link.
- **UID/GID Coordination**: The upstream n8n container runs as the non-root user `node` with UID `1000` and GID `1000`. Declaring ownership `user = "1000"` and `group = "1000"` on `/var/lib/n8n` in preservation and tmpfiles prevents permission denial when n8n creates its SQLite database and configuration files.

### Alternatives Considered
- **External PostgreSQL Container**: n8n supports PostgreSQL for enterprise/high-throughput installations. For a home server, this adds unnecessary RAM consumption, database backups, and networking complexity. SQLite is self-contained and fully backed up by snapshotting `/persistent`.
- **Storing Data in In-Memory / Ephemeral Path**: Rejected as it violates Requirement FR-004 and User Story 2.

---

## 3. Networking, Firewall & Webhook Handling

### Decision
Expose n8n on host port `5678` using Podman port mapping (`"5678:5678"`). Open port `5678` in the host firewall declaratively within `modules/services/n8n.nix`:

```nix
networking.firewall.allowedTCPPorts = [
  5678
];
```

### Rationale
- **Zero Port Collisions**: Verified existing homelab port allocations:
  - Portainer: `8000`, `9443`
  - Filebrowser: `8081`
  - Home Assistant: `8123`
  - Jellyfin: `8096`
  - qBittorrent: `8080`, `6881`
  - Port `5678` is standard for n8n, completely unallocated on `homelab`, and avoids conflicts.
- **Webhook Reachability**: Opening port `5678` allows other devices on the local LAN (e.g., Home Assistant automations or webhooks from local scripts) to trigger workflows directly at `http://homelab:5678/webhook/...`.
- **Remote Access via Tailscale**: For external access without exposing ports to the public internet, `homelab` includes `services.tailscale` (`modules/services/tailscale.nix`), allowing secure remote access over the private overlay network.

### Alternatives Considered
- **Host Networking (`--network=host`)**: While used by Home Assistant for mDNS discovery, n8n does not require raw network interface access or UPnP discovery. Container bridge networking with port mapping is cleaner and more isolated.
- **Reverse Proxy (Nginx/Caddy)**: Currently not deployed for other homelab services (all services expose dedicated LAN ports directly). A reverse proxy can be introduced later if unified TLS domain routing is desired.

---

## 4. Dendritic Integration & Flake Structure

### Decision
1. Create a dedicated dendritic feature module at `modules/services/n8n.nix` defining `flake.modules.services.n8n`.
2. Enable `services.n8n` in `modules/hosts/homelab.nix` under `features = with config.flake.modules; [ ... ]`.
3. Adhere strictly to the Dendritic Pattern: zero inline service logic in `modules/hosts/homelab.nix`.

### Rationale
- **Zero-Boilerplate Discovery**: The root `flake.nix` invokes `(inputs.import-tree ./modules)`, which automatically registers any new `.nix` file under `modules/services/` into `config.flake.modules.services.<filename>`.
- **Constitution Compliance**: Fulfills Constitution Principle II (Dendritic Modularity & Feature-Centric Composition). Host configurations only assemble hardware and enable features; capability logic is colocated with its firewall and persistence settings.

### Alternatives Considered
- **Bundling n8n inside `home-automation.nix`**: Tempting since both relate to automation, but n8n is an independent workflow orchestration tool with distinct ports, storage, and container lifecycle. Separate modules preserve clean modular boundaries.
