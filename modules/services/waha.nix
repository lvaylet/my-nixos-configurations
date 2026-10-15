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
