{
  flake.modules.services.portainer = {
    nixos = {
      config,
      lib,
      vars,
      ...
    }: {
      # Run service as OCI container with `systemd`.
      virtualisation.oci-containers.containers.portainer = {
        # Portainer CE with Podman on Linux - https://docs.portainer.io/start/install-ce/server/podman/linux
        image = "docker.io/portainer/portainer-ce:lts";
        volumes = [
          "/var/run/podman/podman.sock:/var/run/docker.sock" # Link to socket
          "/var/lib/portainer:/data" # Persistent volume
        ];
        ports = [
          # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
          "127.0.0.1:9443:9443"
        ];
        extraOptions = [
          "--label=io.containers.autoupdate=registry"
        ];
      };

      # Wait for `/var/lib/containers` to be mounted.
      systemd.services."podman-portainer".after = [
        "local-fs.target"
      ];

      # Configure Caddy reverse proxy for Portainer on portainer.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."portainer.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy https://127.0.0.1:9443 {
              transport http {
                tls_insecure_skip_verify
              }
            }
          '';
        };
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? portainer) [
        # Persist Portainer data.
        {
          directory = "/var/lib/portainer";
          mode = "0755"; # TODO Why these permissions? Check current owners (user and group).
        }
      ];
    };
  };
}
