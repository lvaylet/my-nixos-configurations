{
  flake.modules.services.sgdf-utils = {
    nixos = {
      config,
      inputs,
      lib,
      pkgs,
      vars,
      ...
    }: {
      imports = [
        inputs.sgdf-utils.nixosModules.default
      ];

      services.sgdf-utils = {
        enable = true;
        # Bind strictly to localhost on port 8000:
        # external and container (n8n) access goes through Caddy reverse proxy on port 443.
        host = "127.0.0.1";
        port = 8000;
        dataDir = "/var/lib/sgdf-utils";
        environmentFile = "/var/lib/sgdf-utils/sgdf-utils.env";
      };

      # Use a static system user and group so `/var/lib/sgdf-utils` can be bind-mounted
      # directly from `/persistent` without conflicting with systemd's `DynamicUser` `/var/lib/private` symlinks.
      users.users.sgdf-utils = {
        isSystemUser = true;
        group = "sgdf-utils";
      };
      users.groups.sgdf-utils = {};

      # Wait for `/var/lib/sgdf-utils` persistent mount before starting the service,
      # and bootstrap a random API key in `/var/lib/sgdf-utils/sgdf-utils.env` on first launch.
      systemd.services.sgdf-utils = {
        after = [
          "local-fs.target"
        ];
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "sgdf-utils";
          Group = "sgdf-utils";
          StateDirectoryMode = "0750";
        };
        preStart = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o sgdf-utils -g sgdf-utils /var/lib/sgdf-utils
          if [ ! -s /var/lib/sgdf-utils/sgdf-utils.env ]; then
            umask 0077
            printf 'SGDF_API_KEY=%s\n' "$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')" > /var/lib/sgdf-utils/sgdf-utils.env
          fi
          ${pkgs.coreutils}/bin/chmod 0600 /var/lib/sgdf-utils/sgdf-utils.env
          ${pkgs.coreutils}/bin/chown sgdf-utils:sgdf-utils /var/lib/sgdf-utils/sgdf-utils.env
        '';
      };

      # Configure Caddy reverse proxy for sgdf-utils on sgdf.<homelabDomain>.
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

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.sgdf-utils.enable [
        # Persist SGDF contacts SQLite database (`sgdf.sqlite3`) and API key (`sgdf-utils.env`).
        {
          directory = "/var/lib/sgdf-utils";
          user = "sgdf-utils";
          group = "sgdf-utils";
          mode = "0750";
        }
      ];
    };
  };
}
