{
  flake.modules.services.caddy = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Centralized Caddy reverse proxy.
      services.caddy = {
        enable = true;
        # Disable automatic HTTP-to-HTTPS redirects and skip local root certificate installation.
        # NixOS maintains a read-only /etc and Caddy runs as an unprivileged user, so attempting
        # to install the internal CA root certificate via `tee` into the system trust store fails.
        globalConfig = ''
          auto_https disable_redirects
          skip_install_trust
        '';
      };

      # Wait for local filesystems to be mounted.
      systemd.services.caddy.after = [
        "local-fs.target"
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
