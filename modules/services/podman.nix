{
  flake.modules.services.podman = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Centralized Podman and OCI container configuration.
      virtualisation = {
        podman = {
          enable = true;
          autoPrune.enable = true;
          dockerCompat = true; # Enable compatibility with Docker commands.
          defaultNetwork.settings.dns_enabled = true; # So containers can communicate with each other based on their names.
        };

        oci-containers = {
          backend = "podman";
        };
      };

      # Conditional preservation mapping (integrated as sub-attribute of config, keeping it top-level clean)
      preservation.preserveAt."/persistent".directories = lib.mkIf config.virtualisation.podman.enable [
        {
          directory = "/var/tmp"; # Podman's default for temporary storage location of downloaded container images.
          # Mode 1777 (rwxrwxrwt): Standard world-writable temporary directory with the sticky bit (1)
          # so both rootful/rootless services and unprivileged users can create temporary files while
          # only file owners (or root) can delete or rename their own entries (overrides preservation's 0755 default).
          mode = "1777";
        }
        "/var/lib/containers" # Podman's default for images and containers in rootful mode.
      ];
    };
  };
}
