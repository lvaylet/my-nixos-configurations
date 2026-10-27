{
  flake.modules.services.jellyfin = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
        group = "multimedia"; # Directly bind Jellyfin to the group for seamless read/write access.
        # TODO Configure `Movies` library declaratively.
      };

      # Configure Caddy reverse proxy for Jellyfin on jellyfin.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."jellyfin.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:8096
          '';
        };
      };

      # Add default `jellyfin` user to `multimedia` group to simplify file sharing with qBittorrent.
      # users.users.jellyfin.extraGroups = [
      #   "multimedia"
      # ];

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.jellyfin.enable [
        # Persist Jellyfin settings, logs and cache:
        # - Program data path: /var/lib/jellyfin
        # - Log directory path: /var/lib/jellyfin/log
        # - Config directory path: /var/lib/jellyfin/config
        # - Cache path: /var/cache/jellyfin
        # - Temp directory path: /tmp/jellyfin
        {
          directory = "/var/lib/jellyfin";
          user = "jellyfin";
          group = config.services.jellyfin.group;
          mode = "0750";
        }
        {
          directory = "/var/cache/jellyfin";
          user = "jellyfin";
          group = config.services.jellyfin.group;
          mode = "0750";
        }
      ];
    };
  };
}
