{
  flake.modules.services.tailscale = {
    nixos = {
      # Tailscale
      # Reference: https://mynixos.com/nixpkgs/options/services.tailscale
      services.tailscale = {
        enable = true;
        # Authorize Caddy to fetch TLS certificates via LocalAPI
        permitCertUid = "caddy";
      };
    };
  };
}
