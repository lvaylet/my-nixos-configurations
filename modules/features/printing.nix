_: {
  flake.nixosModules.printing = {
    # Enable CUPS to print documents.
    services.printing.enable = true;
  };
}
