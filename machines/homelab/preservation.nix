{
  config,
  lib,
  ...
}: {
  boot.tmp.cleanOnBoot = true;

  preservation = {
    enable = true;

    # Use subvolume defined in `disko.nix`.
    preserveAt."/persistent" = {
      directories =
        [
          "/etc/nixos"
          "/var/lib/systemd/timers"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
          "/var/log"
          "/var/lib/bluetooth"
          "/etc/NetworkManager/system-connections"

          "/tmp" # widely used by build tools and editors, may accidentally fill up `tmpfs` root working on big videos or big projects.
        ]
        ++ lib.optionals config.virtualisation.podman.enable [
          "/var/tmp" # Podman's default for temporary storage location of downloaded container images.
          "/var/lib/containers" # Podman's default for images and containers in rootful mode.
        ]
        ++ lib.optionals (config.users.groups ? multimedia) [
          # Mode 2775: The '2' activates the SetGID bit. Any file created within these
          # directories automatically inherits the 'multimedia' group ownership.
          {
            directory = "/data/downloads";
            user = "qbittorrent";
            group = "multimedia";
            mode = "2775"; # SetGID bit + RWX for User/Group, R-X for Others
          }
          {
            directory = "/data/media";
            user = "filebrowser";
            group = "multimedia";
            mode = "2775"; # SetGID bit ensures files moved here stay in the `multimedia`group.
          }
        ]
        ++ lib.optionals (config.virtualisation.oci-containers.containers ? filebrowser) [
          # Persist FileBrowser Quantum settings and cache.
          {
            directory = "/var/lib/filebrowser";
            user = "filebrowser";
            group = "filebrowser";
            mode = "0700";
          }
          {
            directory = "/var/cache/filebrowser";
            user = "filebrowser";
            group = "filebrowser";
            mode = "0700";
          }
        ]
        ++ lib.optionals (config.virtualisation.oci-containers.containers ? homeassistant) [
          # Persist Home Assistant configuration and data in Podman volume.
          {
            directory = "/var/lib/home-assistant";
            mode = "0750";
          }
        ]
        ++ lib.optionals (config.virtualisation.oci-containers.containers ? portainer) [
          # Persist Portainer data.
          {
            directory = "/var/lib/portainer";
            mode = "0755";
          }
        ]
        ++ lib.optionals config.services.caddy.enable [
          # Persist Caddy state.
          {
            directory = "/var/lib/caddy";
            user = "caddy";
            group = "caddy";
            mode = "0750";
          }
        ]
        ++ lib.optionals config.services.cloudflared.enable [
          # Persist Cloudflare Tunnel credentials.
          {
            directory = "/var/lib/cloudflare-tunnel";
            user = "cloudflare-tunnel";
            group = "cloudflare-tunnel";
            mode = "0700";
          }
        ]
        ++ lib.optionals config.services.couchdb.enable [
          # Persist CouchDB data.
          {
            directory = "/var/lib/couchdb";
            user = "couchdb";
            group = "couchdb";
            mode = "0700";
          }
        ]
        ++ lib.optionals config.services.jellyfin.enable [
          # Persist Jellyfin settings, logs and cache:
          {
            directory = "/var/lib/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
            mode = "0750";
          }
          {
            directory = "/var/cache/jellyfin";
            user = "jellyfin";
            group = "jellyfin";
            mode = "0750";
          }
        ]
        ++ lib.optionals config.services.qbittorrent.enable [
          # Persist qBittorrent settings.
          {
            directory = "/var/lib/qBittorrent";
            user = "qbittorrent";
            group = "qbittorrent";
            mode = "0750";
          }
        ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        # Persist SSH host keys with correct permissions.
        # Private keys must be 0600, public keys 0644.
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          mode = "0600";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key";
          mode = "0600";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key.pub";
          mode = "0644";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key.pub";
          mode = "0644";
          configureParent = true;
        }
      ];

      # Preserve user files.
      users.${config.vars.userName} = {
        directories = [
          ".ssh"
          # ".mozilla"
          # ".local/state/wireplumber"
          # ".local/state/neovim"
          # "Documents"
        ];

        files = [
          ".bash_history"
        ];
      };
    };
  };
}
