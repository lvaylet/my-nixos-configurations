{
  self,
  inputs,
  ...
}: {
  # This is your system configuration entry-point.
  flake.nixosConfigurations.legolas = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.legolasConfiguration
      self.nixosModules.myHomeManager
    ];
  };
}
