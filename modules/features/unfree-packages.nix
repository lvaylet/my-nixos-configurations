_: {
  flake.nixosModules.unfreePackages = {
    # Allow unfree packages.
    nixpkgs.config.allowUnfree = true;
  };
}
