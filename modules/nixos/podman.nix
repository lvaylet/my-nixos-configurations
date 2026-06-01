{
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
}
