{
  flake.modules.services.filebrowser = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      # Run service as OCI container with `systemd`.
      virtualisation.oci-containers.containers.filebrowser = {
        # FileBrowser Quantum - https://github.com/gtsteffaniak/filebrowser
        image = "ghcr.io/gtsteffaniak/filebrowser:2-stable";
        volumes = [
          "/data:/srv"
          "/var/lib/filebrowser:/config"
        ];
        environment = {
          PUID = "992"; # Match `filebrowser` user UID in `multimedia.nix`.
          PGID = "995"; # Match `multimedia` group GID in `multimedia.nix`.
          UMASK = "0002"; # Grant rw-rw-r-- (664) to created assets.
          # FILEBROWSER_CONFIG = "/config/config.yaml"; # TODO Is that relevant/required?
          # FILEBROWSER_DATABASE = "/config/filebrowser.db"; # TODO Is that relevant/required?
        };
        ports = [
          # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
          "127.0.0.1:8081:80"
        ];
        extraOptions = [
          "--group-add=995" # Ensure access to `multimedia` group.
        ];
        capabilities = {
          CAP_NET_BIND_SERVICE = true; # Required to bind container port 80 < 1024, even on 8081 > 1024.
        };
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-filebrowser".after = [
        "local-fs.target"
      ];

      # Configure Caddy reverse proxy for FileBrowser Quantum on fb.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."fb.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:8081
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? filebrowser) [
        # Persist FileBrowser Quantum settings and cache.
        {
          directory = "/var/lib/filebrowser";
          user = "filebrowser";
          group = "filebrowser";
          mode = "0700"; # TODO Why these permissions? Check current owners (user and group).
        }
        {
          directory = "/var/cache/filebrowser";
          user = "filebrowser";
          group = "filebrowser";
          mode = "0700"; # TODO Why these permissions? Check current owners (user and group).
        }
      ];
    };
  };
}
