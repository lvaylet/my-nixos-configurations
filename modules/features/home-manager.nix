# Module adding home-manager NixOS module to the imports and configuring it.
{inputs, ...}: {
  # This is your module that imports and configures home-manager
  flake.nixosModules.myHomeManager = {
    imports = [
      inputs.home-manager.nixosModules.default # import official home-manager NixOS module
    ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}
