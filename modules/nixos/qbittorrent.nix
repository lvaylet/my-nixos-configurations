_: {
  services.qbittorrent = {
    enable = true;

    user = "qbittorrent";

    # Enable opening both the webuiPort and torrentingPort over TCP in the firewall.
    openFirewall = true;

    # To persist settings and downloads, `/var/lib/qBittorrent/` must be added  to `preservation.nix`.
    serverConfig = {
      General = {
        Locale = "en";
      };
      Application = {
        FileLogger = {
          Path = "/var/lib/qBittorrent/qBittorrent/data/logs";
        };
      };
      BitTorrent = {
        Session = {
          DefaultSavePath = "/data/downloads";
          TempPath = "/data/downloads/temp";
        };
      };
      Core = {
        AutoDeleteAddedTorrentFile = "Never";
      };
      LegalNotice = {
        Accepted = true;
      };
      Preferences = {
        General = {
          Locale = "en";
        };
        WebUI = {
          Password_PBKDF2 = "@ByteArray(eoaLU7OVVIoPhldUJB+gEg==:zT1YodTdGIZmWZze07O3AhePk44TJUKKNVTYQyi7hERjlldjjlUtAl7S9pM2bqmsE1/Ho+5XF/gtXj1jWnIDMA==)";
        };
      };
    };
  };
}
