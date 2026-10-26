{
  flake.modules.services.tailscale = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Tailscale
      # Reference: https://mynixos.com/nixpkgs/options/services.tailscale
      services.tailscale = {
        enable = true;
        # Authorize Caddy to fetch TLS certificates via LocalAPI
        permitCertUid = "caddy";
        # Enable Tailscale SSH for identity-based access over the tailnet
        extraSetFlags = [
          "--ssh"
        ];
      };

      # Ensure tailscaled-set runs immediately during `nixos-rebuild switch`
      # (via multi-user.target) without requiring a manual tailscaled restart.
      systemd.services.tailscaled-set = {
        wantedBy = ["multi-user.target"];
        partOf = ["tailscaled.service"];
        serviceConfig.RemainAfterExit = true;
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.tailscale.enable [
        {
          directory = "/var/lib/tailscale";
          user = "root";
          group = "root";
          mode = "0700";
        }
      ];
    };
  };
}
