{
  self,
  inputs,
  ...
}: {
  # This is your system configuration entry-point.
  flake.nixosConfigurations.desktop-pc = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.desktopPcConfiguration
      self.nixosModules.myHomeManager
    ];
  };
}
