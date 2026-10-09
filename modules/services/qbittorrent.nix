{
  flake.modules.services.qbittorrent = {
    nixos = _: {
      services.qbittorrent = {
        enable = true;
        # Default port is 8080
        openFirewall = true;
      };
    };
  };
}
