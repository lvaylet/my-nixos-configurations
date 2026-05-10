_: {
  flake.nixosModules.podman = {
    # A daemonless container engine for developing, managing, and running OCI Containers on your Linux System.
    virtualisation = {
      podman.enable = true;
    };
  };
}
