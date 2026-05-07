_: {
  flake.nixosModules.flakes = {
    # Enable Flakes and modern Nix.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
