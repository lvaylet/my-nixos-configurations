_: {
  flake.nixosModules.ssh = {
    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
  };
}
