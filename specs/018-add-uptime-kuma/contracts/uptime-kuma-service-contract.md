# Interface Contract: Uptime Kuma Service Module

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](../spec.md)

This contract defines the NixOS module schema, configuration options, and behavioral guarantees for the Uptime Kuma feature module in `modules/services/uptime-kuma.nix`.

---

## 1. Nix Module Interface

`modules/services/uptime-kuma.nix` MUST export a dendritic NixOS module under `flake.modules.services.uptime-kuma`:

```nix
{
  flake.modules.services.uptime-kuma = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      services.uptime-kuma = {
        enable = true;
        settings = {
          # Bind strictly to localhost on port 3002 (avoiding 3000 AdGuard Home and 3001 WAHA):
          # external access goes through Caddy reverse proxy on port 443.
          HOST = "127.0.0.1";
          PORT = "3002";
        };
      };

      # Expose Podman's Docker-compatible API socket at `/run/docker.sock` (`/var/run/docker.sock`)
      # in addition to `/run/podman/podman.sock` so Uptime Kuma can monitor Portainer-managed containers.
      virtualisation.podman.dockerSocket.enable = true;

      # Use a static system user and group so `/var/lib/uptime-kuma` can be bind-mounted
      # directly from `/persistent` without conflicting with systemd's `DynamicUser` `/var/lib/private` symlinks,
      # and grant membership in the `podman` group to query the Podman/Docker socket.
      users.users.uptime-kuma = {
        isSystemUser = true;
        group = "uptime-kuma";
        extraGroups = [
          "podman"
        ];
      };
      users.groups.uptime-kuma = {};

      # Wait for `/var/lib/uptime-kuma` persistent mount and `podman.socket` before starting the service.
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
          # Disable isolated user namespace so supplementary `podman` group ownership on `/run/podman/podman.sock` is preserved.
          PrivateUsers = lib.mkForce false;
          User = "uptime-kuma";
          Group = "uptime-kuma";
          SupplementaryGroups = [
            "podman"
          ];
          # Allow UNIX domain socket `connect(2)` (which requires write permission on the socket path) under `ProtectSystem = "strict"`.
          ReadWritePaths = [
            "/run/podman"
          ];
        };
      };

      # Configure Caddy reverse proxy for Uptime Kuma on uptime.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."uptime.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:3002
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.uptime-kuma.enable [
        # Persist Uptime Kuma SQLite database, monitors, credentials, and status pages.
        {
          directory = "/var/lib/uptime-kuma";
          user = "uptime-kuma";
          group = "uptime-kuma";
          mode = "0750";
        }
      ];
    };
  };
}
```

---

## 2. Invariants & Guarantees

1. **Reverse Proxy Exposure**: `services.caddy.virtualHosts."uptime.homelab.vaylet.fr"` MUST proxy incoming HTTPS and WebSocket requests on port `443` to `127.0.0.1:3002`.
2. **Loopback Port Security**: `services.uptime-kuma.settings` MUST set `HOST = "127.0.0.1"` and `PORT = "3002"`, and only TCP port `443` may be added to `networking.firewall.allowedTCPPorts`.
3. **Persistent Directory & Static Ownership**: `/var/lib/uptime-kuma` MUST be preserved under `/persistent` (`user = "uptime-kuma"`, `group = "uptime-kuma"`, `mode = "0750"`), with `DynamicUser = lib.mkForce false` on `systemd.services.uptime-kuma.serviceConfig`.
4. **Mount Ordering**: `systemd.services.uptime-kuma.after` MUST include `"local-fs.target"`.
5. **Auto-Discovery**: The module MUST be discovered automatically via `import-tree` as `config.flake.modules.services.uptime-kuma`.
