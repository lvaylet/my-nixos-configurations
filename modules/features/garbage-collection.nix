_: {
  flake.nixosModules.garbageCollection = {
    # Garbage collection and store optimization.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    nix.settings.auto-optimise-store = true;
  };
}
