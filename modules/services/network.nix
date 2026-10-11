{
  flake.modules.services.network = {
    nixos = {
      networking = {
        # Open ports in the firewall.
        # networking.firewall.allowedTCPPorts = [ ... ];
        # networking.firewall.allowedUDPPorts = [ ... ];
        # Or disable the firewall altogether.
        # networking.firewall.enable = false;
        firewall = {
          enable = true;
          # Log refused connections for security auditing.
          logRefusedConnections = true;
        };
        networkmanager.enable = true;
      };
    };
  };
}
