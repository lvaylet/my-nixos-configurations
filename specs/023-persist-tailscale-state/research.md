# Technical Research: Persist Tailscale Node Identity and State Across Impermanent Reboots

**Feature**: `023-persist-tailscale-state`
**Status**: Completed
**Date**: 2026-10-26

---

## 1. Colocating Preservation Rules in `modules/services/tailscale.nix`

### Context

On `homelab`, the root filesystem (`/`) is an ephemeral `tmpfs` mounted in RAM (`modules/hosts/_hardware/homelab.nix`), and persistent state is managed by `nix-community/preservation` (`modules/core/preservation.nix`). Currently, `/var/lib/tailscale` is not registered under `preservation.preserveAt."/persistent".directories`, causing `homelab` to lose its Tailscale node key, authentication credentials (`tailscaled.state`), and daemon settings on every reboot.

### Decision

Declare the `/var/lib/tailscale` preservation entry directly inside `modules/services/tailscale.nix`:

```nix
preservation.preserveAt."/persistent".directories = lib.mkIf config.services.tailscale.enable [
  {
    directory = "/var/lib/tailscale";
    user = "root";
    group = "root";
    mode = "0700";
  }
];
```

### Rationale

- **Dendritic Colocation (Constitution Principle II)**: Every other service module in `modules/services/` (`caddy.nix`, `podman.nix`, `opencode.nix`, `uptime-kuma.nix`, `jellyfin.nix`, `qbittorrent.nix`, `n8n.nix`, `waha.nix`, `filebrowser.nix`, `home-automation.nix`, `portainer.nix`) colocates its `preservation.preserveAt."/persistent"` rules alongside its service definition rather than centralizing service-specific paths in `modules/core/preservation.nix`.
- **Safe Multi-Host Evaluation (`homelab` vs `desktop-pc`)**: `modules/core/lib.nix` (`mkHost`) unconditionally includes `inputs.preservation.nixosModules.default` in all NixOS host evaluations. On `homelab`, `core.preservation` sets `preservation.enable = true`, activating the bind mount. On `desktop-pc`, `preservation.enable` remains `false` (default), so `preservation.preserveAt."/persistent".directories` is evaluated without error as a no-op (matching `modules/services/podman.nix` and `modules/services/opencode.nix`, both of which are also enabled on `desktop-pc` and `homelab`).

### Alternatives Considered

- **Adding `/var/lib/tailscale` to `modules/core/preservation.nix`**:
  - *Rejected*: Violates Dendritic feature encapsulation by separating Tailscale's state path from its service definition, and would persist `/var/lib/tailscale` even on an impermanent host that did not enable `services.tailscale`.

---

## 2. Directory Ownership, Permissions, and Systemd Mount Ordering

### Context

Upstream NixOS `services.tailscale` runs `tailscaled` as `root:root` and stores the node's private key and control-plane credentials in `/var/lib/tailscale/tailscaled.state` (mode `0600` inside a `0700` directory).

### Decision

Configure the preserved directory entry with `user = "root"`, `group = "root"`, and `mode = "0700"`.

### Rationale

- **Security (Constitution Principle IV)**: `/var/lib/tailscale/tailscaled.state` contains the private machine key and wireguard/tailnet secrets. Restricting `/var/lib/tailscale` to `root:root` (`0700`) matches `tailscaled`'s native directory permissions and prevents unprivileged local users or services from inspecting the state directory.
- **Caddy Certificate Access Compatibility**: `services.tailscale.permitCertUid = "caddy"` works over the `tailscaled` Unix socket (`/run/tailscale/tailscaled.sock` LocalAPI), not by reading `/var/lib/tailscale` directly. Therefore `mode = "0700"` owned by `root:root` preserves full compatibility with Caddy's Tailscale certificate fetching.
- **Boot Ordering**: `nix-community/preservation` automatically generates a systemd mount unit (`var-lib-tailscale.mount`) and `systemd-tmpfiles` rules ordered before `local-fs.target` / `sysinit.target`, ensuring `/var/lib/tailscale` is bind-mounted from `/persistent/var/lib/tailscale` before `tailscaled.service` starts.

### Alternatives Considered

- **Default directory string `"/var/lib/tailscale"` (defaulting to `0755`)**:
  - *Rejected*: `0755` is broader than `tailscaled`'s expected `0700` directory mode and unnecessarily exposes directory traversal to non-root users.
