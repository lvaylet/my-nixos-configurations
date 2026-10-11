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
        "/var/tmp" # Podman's default for temporary storage location of downloaded container images.
        "/var/lib/containers" # Podman's default for images and containers in rootful mode.
      ];
    };
  };
}
