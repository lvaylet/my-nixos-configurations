{
  flake.modules.services.n8n = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Run service as OCI container with `systemd`.
      virtualisation.oci-containers.containers.n8n = {
        image = "docker.io/n8nio/n8n:latest";
        volumes = [
          "/var/lib/n8n:/home/node/.n8n"
        ];
        environment = {
          TZ = "Europe/Paris";
          GENERIC_TIMEZONE = "Europe/Paris";
          N8N_PORT = "5678";
          N8N_PROTOCOL = "https";
          N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
        };
        ports = [
          # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 5678.
          "127.0.0.1:5679:5678"
        ];
        user = "1000:1000";
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-n8n".after = [
        "local-fs.target"
      ];

      # Configure Caddy reverse proxy with internal TLS for n8n on port 5678 only.
      services.caddy = {
        enable = true;
        virtualHosts.":5678" = {
          extraConfig = ''
            tls {
              issuer internal
              on_demand
            }
            reverse_proxy 127.0.0.1:5679
          '';
        };
      };

      # Open n8n HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        5678
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? n8n) [
        # Persist n8n configuration, workflows, credentials, and SQLite database.
        {
          directory = "/var/lib/n8n";
          user = "1000";
          group = "1000";
          mode = "0750";
        }
      ];
    };
  };
}
