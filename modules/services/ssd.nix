{
  flake.modules.services.ssd = {
    nixos = _: {
      # Reference: https://mynixos.com/nixpkgs/option/services.fstrim.enable
      services.fstrim.enable = true;
    };
  };
}
