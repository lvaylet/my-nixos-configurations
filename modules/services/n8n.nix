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
          N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
        };
        ports = [
          "5678:5678"
        ];
        user = "1000:1000";
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-n8n".after = [
        "local-fs.target"
      ];

      # Open default n8n port in firewall.
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
