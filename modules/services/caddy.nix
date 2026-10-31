{
  flake.modules.services.caddy = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Centralized Caddy reverse proxy with Cloudflare DNS-01 plugin.
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
          hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
        };
        # Use Cloudflare DNS-01 challenge for ACME certificates.
        # Skip local root certificate installation into read-only /etc.
        globalConfig = ''
          acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          skip_install_trust
        '';
      };

      # Wait for local filesystems to be mounted and Tailscale daemon to be listening.
      systemd.services.caddy = {
        after = [
          "local-fs.target"
          "tailscaled.service"
        ];
        serviceConfig.EnvironmentFile = [
          "-/var/lib/caddy/cloudflare.env"
        ];
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = lib.mkIf config.services.caddy.enable [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.caddy.enable [
        # Persist Caddy configuration, internal CA keys, and certificates.
        {
          directory = "/var/lib/caddy";
          user = "caddy";
          group = "caddy";
          mode = "0750";
        }
      ];
    };
  };
}
