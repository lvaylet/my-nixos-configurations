# Technical Research: WAHA WhatsApp Automation Service for Homelab

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives evaluated for deploying WAHA (WhatsApp HTTP API) on the `homelab` host within the dendritic NixOS configuration.

---

## 1. Deployment Runtime: OCI Container via Podman (`virtualisation.oci-containers`)

### Decision

Deploy WAHA as an OCI container managed by systemd via Podman (`virtualisation.oci-containers.containers.waha`) using the official upstream image `docker.io/devlikeapro/waha:latest`.

### Rationale

- **No Native Nixpkgs Package**: WAHA is not packaged as a native NixOS service in `nixpkgs`, and its runtime bundles specific Node.js/Chromium/WebSocket engines maintained upstream in official container images.
- **Architectural Consistency**: The `homelab` host already standardizes on `virtualisation.oci-containers` (backed by Podman in `modules/services/podman.nix`) for self-hosted web and automation services (`n8n.nix`, `home-automation.nix`, `filebrowser.nix`, `portainer.nix`).
- **Systemd Supervision**: `virtualisation.oci-containers.containers.waha` automatically generates `systemd.services."podman-waha"` with `Restart=on-failure`, journald logging, and declarative dependency ordering.

### Alternatives Considered

- **Custom Nix derivation for WAHA**: High maintenance burden due to frequent upstream WhatsApp protocol adjustments and bundled browser/engine binaries. Rejected in favor of the official OCI image.
- **Docker daemon (`virtualisation.docker`)**: Redundant since `homelab` already uses Podman with `dockerCompat = true`.

---

## 2. Reverse Proxy Exposure & Port Allocation (`waha.homelab.vaylet.fr`)

### Decision

Bind the WAHA container's internal HTTP port (`3000`) strictly to host loopback port `3001` (`"127.0.0.1:3001:3000"`) and expose it over HTTPS at `waha.${vars.homelabDomain}` (`waha.homelab.vaylet.fr`) via `services.caddy`:

```nix
services.caddy = {
  enable = true;
  virtualHosts."waha.${vars.homelabDomain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3001
    '';
  };
};
```

### Rationale

- **Consistent Homelab Exposure Pattern**: Matches `modules/services/n8n.nix` (`n8n.${vars.homelabDomain}` -> `127.0.0.1:5679`), `modules/services/home-automation.nix` (`ha.${vars.homelabDomain}` -> `127.0.0.1:8123`), `modules/services/filebrowser.nix` (`fb.${vars.homelabDomain}` -> `127.0.0.1:8081`), and `modules/services/portainer.nix` (`portainer.${vars.homelabDomain}` -> `127.0.0.1:9443`).
- **Loopback Isolation**: Binding to `127.0.0.1:3001` ensures the unencrypted HTTP port cannot be accessed directly from the LAN or Tailscale network, forcing all traffic through Caddy's HTTPS termination (`FR-002`, `FR-003`).
- **Port Collision Avoidance**: WAHA listens on port `3000` inside the container. In this repository, `modules/services/adguardhome.nix` allocates host port `3000`. Mapping WAHA to `127.0.0.1:3001:3000` prevents any current or future port conflict on `homelab`.
- **Base URL Alignment**: Setting `WAHA_BASE_URL = "https://waha.${vars.homelabDomain}"` ensures WAHA generates valid public HTTPS links for downloaded media artifacts and Swagger API definitions behind the reverse proxy.

### Alternatives Considered

- **Exposing port 3000 directly on all interfaces (`"3000:3000"`)**: Violates `FR-003` (exposes unencrypted HTTP traffic directly on the network) and risks colliding with `adguardhome.nix`. Rejected.

---

## 3. Session Persistence, Automatic Reconnection & Ephemeral Root Handling

### Decision

Persist `/var/lib/waha` under `/persistent/var/lib/waha` via `preservation.preserveAt."/persistent".directories`, create subdirectories `/var/lib/waha/sessions` and `/var/lib/waha/media` in `systemd.services."podman-waha".preStart`, mount them to `/app/.sessions` and `/app/.media`, and enable automatic session restoration via `WHATSAPP_RESTART_ALL_SESSIONS = "True"`.

```nix
virtualisation.oci-containers.containers.waha = {
  image = "docker.io/devlikeapro/waha:latest";
  volumes = [
    "/var/lib/waha/sessions:/app/.sessions"
    "/var/lib/waha/media:/app/.media"
  ];
  environment = {
    TZ = "Europe/Paris";
    WAHA_BASE_URL = "https://waha.${vars.homelabDomain}";
    WHATSAPP_RESTART_ALL_SESSIONS = "True";
  };
  environmentFiles = [
    "/var/lib/waha/waha.env"
  ];
  ports = [
    "127.0.0.1:3001:3000"
  ];
};
```

### Rationale

- **Ephemeral Root Survival**: `homelab` uses `preservation` with an ephemeral root filesystem. Preserving `/var/lib/waha` under `/persistent` keeps both session authentication tokens (`/var/lib/waha/sessions`) and downloaded/sent media (`/var/lib/waha/media`) intact across reboots.
- **Unattended Session Recovery**: By default, WAHA only persists session files if `/app/.sessions` is mounted AND only auto-starts previously active sessions on container launch when `WHATSAPP_RESTART_ALL_SESSIONS=True` is set. Together, these satisfy `FR-005`, `FR-006`, and `SC-002`.
- **Mount Ordering**: Setting `systemd.services."podman-waha".after = [ "local-fs.target" ]` ensures `/persistent` bind mounts are active before Podman starts the container.

### Alternatives Considered

- **Mounting `/var/lib/waha` directly to `/app/.sessions`**: Would mix media files and `waha.env` inside the container's session directory. Separating `/var/lib/waha/sessions` and `/var/lib/waha/media` under the single preserved `/var/lib/waha` parent directory keeps `waha.env` strictly on the host filesystem outside container volume mounts.

---

## 4. Secret & Credential Management (`waha.env`)

### Decision

Load WAHA authentication secrets (`WAHA_API_KEY`, `WAHA_DASHBOARD_USERNAME`, `WAHA_DASHBOARD_PASSWORD`, `WHATSAPP_SWAGGER_USERNAME`, `WHATSAPP_SWAGGER_PASSWORD`) from `/var/lib/waha/waha.env` via `environmentFiles = [ "/var/lib/waha/waha.env" ]`, ensuring the file is initialized if absent in `preStart` with `0600` permissions:

```nix
systemd.services."podman-waha" = {
  after = [
    "local-fs.target"
  ];
  preStart = lib.mkBefore ''
    mkdir -p /var/lib/waha/sessions /var/lib/waha/media
    touch /var/lib/waha/waha.env
    chmod 0600 /var/lib/waha/waha.env
  '';
};
```

### Rationale

- **Clarified Requirement (`FR-008`)**: Per the clarification session, credentials are stored in `/var/lib/waha/waha.env` on the persistent host filesystem outside Git, matching `/var/lib/caddy/cloudflare.env` in `modules/services/caddy.nix`.
- **Zero First-Boot Failure**: `podman run --env-file` fails if the referenced file does not exist. Ensuring `touch /var/lib/waha/waha.env` and `chmod 0600 /var/lib/waha/waha.env` run in `preStart` guarantees the service starts cleanly on first deployment while protecting any secrets placed in `waha.env`.
- **Stable n8n Integration**: Unlike WAHA's default behavior (which generates new random credentials on every container start when env vars are unset), defining them in `/var/lib/waha/waha.env` keeps the API key constant for `n8n` workflows across restarts.

### Alternatives Considered

- **Hardcoding credentials in `modules/services/waha.nix`**: Violates Constitution Principle IV (Zero-Secrets Leakage & Security First) and would fail `ripsecrets`/`trufflehog` pre-commit hooks. Rejected.
