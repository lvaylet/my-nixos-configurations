{
  config,
  inputs,
  ...
}: {
  # Custom ISO installation image with SSH access for remote deployments
  # ---
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      outputs = config.flake;
      vars = config.flake.vars;
    };
    modules = [
      (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
      config.flake.modules.core.iso.nixos
      {
        networking.hostName = "iso";
      }
    ];
  };
}
