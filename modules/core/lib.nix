{
  config,
  inputs,
  lib,
  ...
}: {
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
    default = {};
    description = "Dendritic feature modules grouped by domain";
  };

  config.flake.lib = {
    mkHost = {
      system ? "x86_64-linux",
      hardware ? null,
      features ? [],
      extraModules ? [],
    }: let
      nixosModules = lib.flatten (
        map (
          f:
            if builtins.isAttrs f && f ? nixos
            then f.nixos
            else if builtins.isAttrs f && f ? homeManager
            then []
            else if builtins.isFunction f || builtins.isAttrs f || builtins.isPath f
            then f
            else []
        )
        features
      );

      homeManagerModules = lib.flatten (
        map (
          f:
            if builtins.isAttrs f && f ? homeManager
            then f.homeManager
            else []
        )
        features
      );
    in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          outputs = config.flake;
          vars = config.flake.vars;
        };
        modules =
          (lib.optional (hardware != null) hardware)
          ++ nixosModules
          ++ [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs;
                  outputs = config.flake;
                  vars = config.flake.vars;
                };
                users.${config.flake.vars.userName} = {
                  imports = homeManagerModules;
                };
              };
            }
          ]
          ++ extraModules;
      };
  };
}
