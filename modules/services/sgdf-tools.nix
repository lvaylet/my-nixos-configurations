{
  flake.modules.services.sgdf-tools = {
    nixos = {
      config,
      inputs,
      lib,
      pkgs,
      vars,
      ...
    }: {
      imports = [
        inputs.sgdf-tools.nixosModules.default
      ];

      services.sgdf-api = {
        enable = true;
        # Bind strictly to localhost on port 8000:
        # external and container (n8n) access goes through Caddy reverse proxy on port 443.
        host = "127.0.0.1";
        port = 8000;
        dataDir = "/var/lib/sgdf-tools";
      };

      # Install sgdf-cli (`sgdf`) on the host and point it to the local API listener by default.
      environment.systemPackages = [
        inputs.sgdf-tools.packages.${pkgs.stdenv.hostPlatform.system}.sgdf-cli
      ];
      environment.variables.SGDF_API_URL = "http://127.0.0.1:8000";

      # Use a static system user and group so `/var/lib/sgdf-tools` can be bind-mounted
      # directly from `/persistent` without conflicting with systemd's `DynamicUser` `/var/lib/private` symlinks.
      users.users.sgdf-tools = {
        isSystemUser = true;
        group = "sgdf-tools";
      };
      users.groups.sgdf-tools = {};

      # Wait for `/var/lib/sgdf-tools` persistent mount before starting the service,
      # and bootstrap a random Bearer token in `/var/lib/sgdf-tools/sgdf-tools.env` on first launch.
      systemd.services.sgdf-api = {
        after = [
          "local-fs.target"
        ];
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "sgdf-tools";
          Group = "sgdf-tools";
          StateDirectoryMode = "0750";
          # Leading '-' allows ExecStartPre (`preStart`) to run and create `sgdf-tools.env` on first boot
          # before `ExecStart` loads it (without '-', systemd aborts before spawning `start-pre` when the file is missing).
          EnvironmentFile = "-/var/lib/sgdf-tools/sgdf-tools.env";
        };
        preStart = ''
          if [ ! -s /var/lib/sgdf-tools/sgdf-tools.env ]; then
            umask 0077
            printf 'SGDF_AUTH_TOKEN=%s\n' "$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')" > /var/lib/sgdf-tools/sgdf-tools.env
          fi
          ${pkgs.coreutils}/bin/chmod 0600 /var/lib/sgdf-tools/sgdf-tools.env
        '';
      };

      # Configure Caddy reverse proxy for sgdf-api on sgdf.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."sgdf.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:8000
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.sgdf-api.enable [
        # Persist SGDF Tools SQLite database (`sgdf.db`) and Bearer token (`sgdf-tools.env`).
        {
          directory = "/var/lib/sgdf-tools";
          user = "sgdf-tools";
          group = "sgdf-tools";
          mode = "0750";
        }
      ];
    };
  };
}
