{
  flake.modules.services.media = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      users = {
        groups = {
          multimedia = {
            gid = 995; # Fix GID to ensure persistent files retain consistent group ownership.
          };
          qbittorrent = {};
          filebrowser = {};
        };
        users = {
          qbittorrent = {
            isSystemUser = true;
            uid = 991;
            group = "qbittorrent";
          };
          filebrowser = {
            isSystemUser = true;
            uid = 992;
            group = "filebrowser";
          };
          ${vars.userName} = {
            extraGroups = [
              "multimedia" # Let user manage qBittorrent, Filebrowser Quantum and Jellyfin files and directories.
            ];
          };
        };
      };

      # =========================================================================
      # SYSTEMD TMPFILES (PERMISSION ENFORCEMENT POST-MOUNT)
      # =========================================================================
      # CRITICAL FOR IMPERMANENCE: We use the 'z' rule instead of 'd'.
      # 'd' would try to create directories before or during the preservation mount,
      # creating conflicts.
      # 'z' acts as a "mop-up" operation: it waits until the path exists (after
      # preservation links it), then forces the specified ownership and modes.
      systemd.tmpfiles.rules = [
        #z /path           mode user        group      argument
        "z /data           0775 root        multimedia -"
        "z /data/downloads 2775 qbittorrent multimedia -"
        "z /data/media     2775 filebrowser multimedia -"
      ];

      systemd.services.qbittorrent = {
        serviceConfig = {
          SupplementaryGroups = [
            "multimedia" # Allow writing to shared directories.
          ];
          UMask = "0002"; # Grant rw-rw-r-- (664) to created assets.
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.users.groups ? multimedia) [
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
      ];
    };
  };
}
