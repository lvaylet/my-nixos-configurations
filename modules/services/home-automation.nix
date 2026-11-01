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
          "--label=io.containers.autoupdate=registry"
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
