_: {
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
}
