{
  flake.modules.services.uptime-kuma = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      services.uptime-kuma = {
        enable = true;
        settings = {
          # Bind strictly to localhost on port 3002 (avoiding 3000 AdGuard Home and 3001 WAHA):
          # external access goes through Caddy reverse proxy on port 443.
          HOST = "127.0.0.1";
          PORT = "3002";
        };
      };

      # Expose Podman's Docker-compatible API socket at `/run/docker.sock` (`/var/run/docker.sock`)
      # in addition to `/run/podman/podman.sock` so Uptime Kuma can monitor Portainer-managed containers.
      virtualisation.podman.dockerSocket.enable = true;

      # Use a static system user and group so `/var/lib/uptime-kuma` can be bind-mounted
      # directly from `/persistent` without conflicting with systemd's `DynamicUser` `/var/lib/private` symlinks,
      # and grant membership in the `podman` group to query the Podman/Docker socket.
      users.users.uptime-kuma = {
        isSystemUser = true;
        group = "uptime-kuma";
        extraGroups = [
          "podman"
        ];
      };
      users.groups.uptime-kuma = {};

      # Wait for `/var/lib/uptime-kuma` persistent mount and `podman.socket` before starting the service.
      systemd.services.uptime-kuma = {
        after = [
          "local-fs.target"
          "podman.socket"
        ];
        requires = [
          "podman.socket"
        ];
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          # Disable isolated user namespace so supplementary `podman` group ownership on `/run/podman/podman.sock` is preserved.
          PrivateUsers = lib.mkForce false;
          User = "uptime-kuma";
          Group = "uptime-kuma";
          SupplementaryGroups = [
            "podman"
          ];
          # Allow UNIX domain socket `connect(2)` (which requires write permission on the socket path) under `ProtectSystem = "strict"`.
          ReadWritePaths = [
            "/run/podman"
          ];
        };
      };

      # Configure Caddy reverse proxy for Uptime Kuma on uptime.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."uptime.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:3002
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.uptime-kuma.enable [
        # Persist Uptime Kuma SQLite database, monitors, credentials, and status pages.
        {
          directory = "/var/lib/uptime-kuma";
          user = "uptime-kuma";
          group = "uptime-kuma";
          mode = "0750";
        }
      ];
    };
  };
}
