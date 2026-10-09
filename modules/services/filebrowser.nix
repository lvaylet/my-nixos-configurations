{
  flake.modules.services.filebrowser = {
    nixos = _: {
      services.filebrowser = {
        enable = true;
        settings = {
          port = 8081;
          address = "0.0.0.0";
        };
      };

      networking.firewall.allowedTCPPorts = [
        8081
      ];
    };
  };
}
