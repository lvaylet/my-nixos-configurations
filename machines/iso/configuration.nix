{...}: {
  networking.hostName = "iso";

  imports = [
    ./../../modules/nixos/iso.nix
  ];
}
