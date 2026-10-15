# Interface Contract: WAHA Service Module

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](../spec.md)

This contract defines the NixOS module schema, configuration options, and behavioral guarantees for the WAHA feature module in `modules/services/waha.nix`.

---

## 1. Nix Module Interface

`modules/services/waha.nix` MUST export a dendritic NixOS module under `flake.modules.services.waha`:

```nix
{
  flake.modules.services.waha = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      # Run service as OCI container with `systemd`.
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
          # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
          "127.0.0.1:3001:3000"
        ];
      };

      # Wait for `/var/lib/containers` and `/var/lib/waha` to be mounted, and ensure persistent subdirectories and env file exist.
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

      # Configure Caddy reverse proxy for WAHA on waha.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."waha.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:3001
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? waha) [
        # Persist WAHA sessions, media, and environment secrets file.
        {
          directory = "/var/lib/waha";
          mode = "0750";
        }
      ];
    };
  };
}
```

---

## 2. Invariants & Guarantees

1. **Reverse Proxy Exposure**: `services.caddy.virtualHosts."waha.homelab.vaylet.fr"` MUST proxy incoming HTTPS requests on port `443` to `127.0.0.1:3001`.
2. **Loopback Port Security**: The container port mapping MUST be `"127.0.0.1:3001:3000"` and only TCP port `443` may be added to `networking.firewall.allowedTCPPorts`.
3. **Persistent Directory & Secret File**: `/var/lib/waha` MUST be preserved under `/persistent` (`mode = "0750"`), and `preStart` MUST initialize `/var/lib/waha/sessions`, `/var/lib/waha/media`, and `/var/lib/waha/waha.env` (`0600`).
4. **Automatic Session Restoration**: `WHATSAPP_RESTART_ALL_SESSIONS = "True"` MUST be set so paired WhatsApp sessions reconnect automatically after container or host restarts.
5. **Timezone Harmonization**: `TZ` MUST be set to `"Europe/Paris"`.
6. **Auto-Discovery**: The module MUST be discovered automatically via `import-tree` as `config.flake.modules.services.waha`.
