# Contract: Portainer and Home Assistant Security Hardening & Documentation

**Feature**: `025-secure-portainer-homeassistant`
**Date**: 2026-10-26

---

## 1. Portainer Dendritic Module Contract (`modules/services/portainer.nix`)

The `services.portainer` dendritic feature module MUST bind Portainer strictly to `127.0.0.1:9443:9443`, omit `--privileged`, and not open ports `8000` or `9443` in the firewall:

```nix
{
  flake.modules.services.portainer = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      # Run service as OCI container with `systemd`.
      virtualisation.oci-containers.containers.portainer = {
        # Portainer CE with Podman on Linux - https://docs.portainer.io/start/install-ce/server/podman/linux
        image = "docker.io/portainer/portainer-ce:lts";
        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock" # Link to socket
          "/var/lib/portainer:/data" # Persistent volume
        ];
        ports = [
          # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
          "127.0.0.1:9443:9443"
        ];
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-portainer".after = [
        "local-fs.target"
      ];

      # Configure Caddy reverse proxy for Portainer on portainer.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."portainer.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy https://127.0.0.1:9443 {
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? portainer) [
        # Persist Portainer data.
        {
          directory = "/var/lib/portainer";
          mode = "0755"; # TODO Why these permissions? Check current owners (user and group).
        }
      ];
    };
  };
}
```

---

## 2. Home Assistant Dendritic Module Contract (`modules/services/home-automation.nix`)

The `services.home-automation` dendritic feature module MUST remove `networking.firewall.allowedTCPPorts = [ 443 8123 ];` so that port `443` is managed centrally by `modules/services/caddy.nix` and port `8123` is not exposed to unencrypted LAN traffic:

```nix
{
  flake.modules.services.home-automation = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      # Run service as OCI container with `systemd`.
      virtualisation.oci-containers.containers.homeassistant = {
        # https://www.home-assistant.io/installation/generic-x86-64/#install-home-assistant-container
        image = "ghcr.io/home-assistant/home-assistant:2026.10"; # or `:stable`
        volumes = [
          "/var/lib/home-assistant:/config" # Make sure to persist this volume in `preservation.nix`.
          "/run/dbus:/run/dbus:ro" # Optional: useful for bluetooth/network discovery.
        ];
        environment = {
          TZ = "Europe/Paris";
        };
        extraOptions = [
          # Use the host network namespace for all sockets with mDNS/UPnP discovery.
          "--network=host"
          # Pass devices into the container, so Home Assistant can discover and make use of them.
          # "--device=/dev/ttyACM0:/dev/ttyACM0"
        ];
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-homeassistant".after = [
        "local-fs.target"
      ];

      # Configure Caddy reverse proxy for Home Assistant on ha.<homelabDomain>.
      # Note: In Home Assistant (>= 2026.10), reverse proxy trust is configured via the UI:
      #   Settings > System > Network > Reverse Proxy:
      #     - Enable "Use reverse proxy"
      #     - Trusted proxies: 127.0.0.1, ::1
      # (The legacy `http:` block in configuration.yaml is deprecated and ignored).
      services.caddy = {
        enable = true;
        virtualHosts."ha.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:8123
          '';
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? homeassistant) [
        # Persist Home Assistant configuration and data in Podman volume.
        {
          directory = "/var/lib/home-assistant";
          mode = "0750"; # TODO Why these permissions? Check current owners (user and group).
        }
      ];
    };
  };
}
```

### Evaluation Postconditions on `homelab`

1. `config.virtualisation.oci-containers.containers.portainer.ports` equals `["127.0.0.1:9443:9443"]`.
2. `config.virtualisation.oci-containers.containers.portainer.extraOptions` equals `[]`.
3. `config.networking.firewall.allowedTCPPorts` does NOT contain `8000`, `9443`, or `8123`, and DOES contain `443`.
4. `config.services.caddy.virtualHosts."portainer.homelab.vaylet.fr"` and `config.services.caddy.virtualHosts."ha.homelab.vaylet.fr"` remain configured.

---

## 3. Documentation Contract (`README.md`)

`README.md` MUST be updated within the same branch:

1. In the **Homelab Hosted Services** table:
   - **Home Assistant**: **Network / Ports** -> `443` (HTTPS via Caddy) (remove `, 8123 (LAN HTTP)`).
   - **Portainer CE**: **Network / Ports** -> `443` (HTTPS via Caddy) (remove `, 9443 (HTTPS), 8000 (TCP)`).
2. In the **Reverse Proxy & Secure HTTPS Access** table:
   - **Home Assistant**: **LAN Direct URL** -> `N/A (loopback bound)` (replace `http://homelab:8123`).
   - **Portainer CE**: **LAN Direct URL** -> `N/A (loopback bound)` (replace `https://homelab:9443`).
3. In section **3. Home Assistant Reverse Proxy Authorization (UI Configuration)**:
   - Replace direct LAN access (`http://homelab:8123`) with SSH local port forwarding (`ssh -L 8123:127.0.0.1:8123 laurent@homelab` -> `http://127.0.0.1:8123`) with explicit **Bash** and **Fish** blocks.
