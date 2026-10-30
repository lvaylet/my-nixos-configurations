# Technical Research: Uptime Kuma Monitoring Service for Homelab

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives evaluated for deploying Uptime Kuma on the `homelab` host within the dendritic NixOS configuration.

---

## 1. Deployment Runtime: Native NixOS Service (`services.uptime-kuma`) vs OCI Container

### Decision

Deploy Uptime Kuma using the native NixOS module (`services.uptime-kuma.enable = true`) backed by `pkgs.uptime-kuma` (`v2.5.6` in the pinned `nixpkgs` flake input).

### Rationale

- **Binary Cache & Free License**: Unlike `pkgs.n8n` (which carries an unfree license and is absent from `cache.nixos.org`), `pkgs.uptime-kuma` is licensed under the MIT license (`free = true`) and is pre-built and cached directly in `https://cache.nixos.org`, requiring zero local source compilation on the Intel N150 mini PC.
- **Direct Host Network Reachability for Local Loopback Targets**: On `homelab`, several services bind exclusively to the host loopback interface (`127.0.0.1`), such as `n8n` (`127.0.0.1:5679`) and `waha` (`127.0.0.1:3001`). Running Uptime Kuma as a native systemd service in the host network namespace (while binding its own HTTP server strictly to `127.0.0.1:3002`) allows it to monitor:
  1. All loopback-only homelab services (`http://127.0.0.1:5679`, `http://127.0.0.1:3001`, `http://127.0.0.1:8123`, `http://127.0.0.1:8081`, `http://127.0.0.1:8096`, `http://127.0.0.1:8080`, `https://127.0.0.1:9443`).
  2. All external HTTPS reverse-proxy endpoints (`https://*.homelab.vaylet.fr`) over Tailscale/Caddy.
  3. ICMP `ping` targets on the local LAN and internet (`pkgs.unixtools.ping` is automatically added to `systemd.services.uptime-kuma.path` by the NixOS module).
- **Built-in Systemd Sandboxing**: The upstream NixOS `services.uptime-kuma` module configures strict systemd unit hardening out of the box (`ProtectSystem = "strict"`, `ProtectHome = true`, `PrivateTmp = true`, `PrivateDevices = true`, `NoNewPrivileges = true`, `LockPersonality = true`, `ProtectKernelTunables = true`, `SystemCallArchitectures = "native"`).
- **Precedent in Repository**: Matches the native service pattern already used in `modules/services/caddy.nix`, `modules/services/jellyfin.nix`, and `modules/services/qbittorrent.nix`.

### Alternatives Considered

- **OCI Container (`docker.io/louislam/uptime-kuma:1`) via Podman**: In a default rootful bridge-networked container, `127.0.0.1` resolves to the container's own loopback rather than the `homelab` host's loopback, preventing direct health checks against loopback-bound services (`n8n` on `127.0.0.1:5679` and `waha` on `127.0.0.1:3001`) unless `--network=host` is used. Since `pkgs.uptime-kuma` is natively packaged, MIT-licensed, cached in `cache.nixos.org`, and hardened with systemd sandboxing, the native NixOS service is cleaner, lighter, and more reproducible.

---

## 2. Port Allocation & Reverse Proxy Exposure (`uptime.homelab.vaylet.fr`)

### Decision

Configure Uptime Kuma to listen strictly on `127.0.0.1:3002` via `services.uptime-kuma.settings` and expose it over HTTPS at `uptime.${vars.homelabDomain}` (`uptime.homelab.vaylet.fr`) via `services.caddy`:

```nix
services.uptime-kuma = {
  enable = true;
  settings = {
    HOST = "127.0.0.1";
    PORT = "3002";
  };
};

services.caddy = {
  enable = true;
  virtualHosts."uptime.${vars.homelabDomain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:3002
    '';
  };
};
```

### Rationale

- **Port Collision Avoidance (`3001` vs `3002`)**: By default, `services.uptime-kuma` sets `PORT = lib.mkDefault "3001"`. On `homelab`, `127.0.0.1:3001` is already bound by `modules/services/waha.nix` (`"127.0.0.1:3001:3000"`), and port `3000` is reserved in `modules/services/adguardhome.nix`. Assigning `PORT = "3002"` avoids any port conflict across all `homelab` services (`3000`, `3001`, `5679`, `8000`, `8080`, `8081`, `8096`, `8123`, `9443`).
- **Loopback Isolation**: Binding `HOST = "127.0.0.1"` and only opening TCP port `443` in `networking.firewall.allowedTCPPorts` guarantees that unencrypted traffic on port `3002` is unreachable from outside the host (`FR-002`, `FR-003`, `SC-005`).
- **Native WebSocket Support in Caddy**: Uptime Kuma uses Socket.IO over WebSockets for real-time dashboard updates. Caddy 2's `reverse_proxy 127.0.0.1:3002` directive natively handles HTTP/1.1 `Upgrade: websocket` and `Connection: Upgrade` headers with zero extra configuration (`FR-004`, `SC-003`).

### Alternatives Considered

- **Keeping default port `3001`**: Would collide at runtime with `podman-waha.service` on `127.0.0.1:3001`, causing one of the services to fail to bind. Rejected.
- **Opening port `3002` in the host firewall**: Unnecessary and bypasses TLS encryption; all access goes through `https://uptime.homelab.vaylet.fr` on port `443`. Rejected.

---

## 3. Impermanence (`preservation`) & Systemd `DynamicUser` Interaction

### Decision

Disable `DynamicUser` (`DynamicUser = lib.mkForce false`) and `PrivateUsers` (`PrivateUsers = lib.mkForce false`) on `systemd.services.uptime-kuma`, declare a static `uptime-kuma` system user and group (`users.users.uptime-kuma` / `users.groups.uptime-kuma`) with supplementary group `podman`, enable `virtualisation.podman.dockerSocket.enable = true`, order `systemd.services.uptime-kuma` after `local-fs.target` and `podman.socket` (`requires = [ "podman.socket" ]`), grant `ReadWritePaths = [ "/run/podman" ]`, and preserve `/var/lib/uptime-kuma` under `/persistent` with owner `uptime-kuma:uptime-kuma` and mode `0750`:

```nix
virtualisation.podman.dockerSocket.enable = true;

users.users.uptime-kuma = {
  isSystemUser = true;
  group = "uptime-kuma";
  extraGroups = [
    "podman"
  ];
};
users.groups.uptime-kuma = {};

systemd.services.uptime-kuma = {
  after = [
    "local-fs.target"
    "podman.socket"
  ];
  requires = [
    "podman.socket"
  ];
  serviceConfig = {
    DynamicUser = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
    User = "uptime-kuma";
    Group = "uptime-kuma";
    SupplementaryGroups = [
      "podman"
    ];
    ReadWritePaths = [
      "/run/podman"
    ];
  };
};

preservation.preserveAt."/persistent".directories = lib.mkIf config.services.uptime-kuma.enable [
  {
    directory = "/var/lib/uptime-kuma";
    user = "uptime-kuma";
    group = "uptime-kuma";
    mode = "0750";
  }
];
```

### Rationale

- **Avoiding `DynamicUser` + Bind-Mount Conflicts**: By default, `services.uptime-kuma` sets `DynamicUser = true` and `StateDirectory = "uptime-kuma"`. Under systemd's `DynamicUser` mechanism, `/var/lib/uptime-kuma` is expected to be a symlink pointing to `/var/lib/private/uptime-kuma` owned by a transient UID/GID (`61184..65519`), and `config.users.users.uptime-kuma` does not exist at Nix evaluation time (which would break `preservation`'s user/group lookup). Furthermore, when `preservation` bind-mounts `/persistent/var/lib/uptime-kuma` onto `/var/lib/uptime-kuma`, `DynamicUser = true` fails during service startup because systemd cannot replace a mountpoint directory with a symlink to `/var/lib/private/uptime-kuma`.
- **Monitoring Portainer-Managed Containers via Podman Socket**:
  - Portainer manages `homelab`'s OCI containers via Podman's rootful Docker-compatible API socket at `/run/podman/podman.sock` (owned by `root:podman`, mode `0660`).
  - Enabling `virtualisation.podman.dockerSocket.enable = true` configures `systemd.sockets.podman` to symlink `/run/docker.sock` (`/var/run/docker.sock`) to `/run/podman/podman.sock`, matching Uptime Kuma's default Docker Host socket path as well as `/var/run/podman/podman.sock`.
  - Setting `PrivateUsers = lib.mkForce false` is mandatory because `PrivateUsers = true` creates an isolated user namespace that maps all supplementary groups (including `podman`) to `nobody`/`nogroup` (`65534`), which would prevent the `uptime-kuma` user from authenticating to the `root:podman` (`0660`) socket.
  - Adding `ReadWritePaths = [ "/run/podman" ]` is mandatory under `ProtectSystem = "strict"` because `connect(2)` on a Linux UNIX domain socket checks `MAY_WRITE` on the mountpoint and would fail with `EROFS` if `/run/podman` remained mounted read-only inside the service's mount namespace.
- **Static System User Pattern**: Setting `DynamicUser = lib.mkForce false` with a static `uptime-kuma` user and group keeps `/var/lib/uptime-kuma` as a standard directory owned by `uptime-kuma:uptime-kuma` (`0750`), matching `modules/services/caddy.nix`, `modules/services/jellyfin.nix`, and `modules/services/qbittorrent.nix` while retaining all other systemd sandboxing flags (`ProtectSystem = "strict"`, `ProtectHome = true`, `PrivateTmp = true`, `NoNewPrivileges = true`, etc.).

### Alternatives Considered

- **Preserving `/var/lib/private/uptime-kuma` with `DynamicUser = true`**: Fragile across reboots because dynamic UID/GID allocation is managed at runtime in `/var/lib/nixos` or systemd transient state, and `preservation`'s `user`/`group` options reference `config.users.users`. Using an explicit system user `uptime-kuma` is deterministic and consistent with the rest of the codebase.

---

## 4. Documentation Synchronization (`README.md`)

### Decision

Update `README.md` within the same branch in accordance with Constitution Principle VI (*Living Documentation & Dual-Shell Parity*):

1. Add `Uptime Kuma` to the `modules/services/` architecture tree comment.
2. Add a row for **Uptime Kuma** in the **Homelab Hosted Services** table (`Native Service`, `443 (HTTPS via Caddy)`, `/var/lib/uptime-kuma`).
3. Add a row for **Uptime Kuma** in the **Reverse Proxy & Secure HTTPS Access** table (`https://uptime.homelab.vaylet.fr`, `127.0.0.1:3002`, `N/A (loopback bound)`).

### Rationale

- **Constitutional Compliance**: Directly satisfies Principle VI and Quality Gate 2 of `.specify/memory/constitution.md` (v2.1.0).
- **No Shell-Specific Secret Provisioning Needed**: Because Uptime Kuma initializes its administrator credentials and SQLite database (`kuma.db`) interactively via its web UI on first visit and stores them in `/var/lib/uptime-kuma` (`/persistent/var/lib/uptime-kuma`), no manual `.env` file creation on the host is required.
