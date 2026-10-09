{
  flake.modules.services.tailscale = {
    nixos = {
      # Tailscale
      # Reference: https://mynixos.com/nixpkgs/options/services.tailscale
      services.tailscale.enable = true;
    };
  };
}
