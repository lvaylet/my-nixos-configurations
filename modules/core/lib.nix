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

  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "Flake library functions and shared helpers";
  };

  config.flake.lib = {
    mkHost = {
      system ? "x86_64-linux",
      hardware ? null,
      features ? [],
      extraModules ? [],
      enableHomeManager ? null,
    }: let
      nixosModules = lib.flatten (
        map (
          f:
            if builtins.isAttrs f && f ? nixos
            then f.nixos
            else if builtins.isAttrs f && (f ? homeManager || f ? darwin)
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

      hasHomeManager =
        if enableHomeManager != null
        then enableHomeManager
        else (homeManagerModules != []);
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
            inputs.disko.nixosModules.disko
            inputs.preservation.nixosModules.default
          ]
          ++ (lib.optionals hasHomeManager [
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
          ])
          ++ extraModules;
      };

    mkDarwinHost = {
      system ? "aarch64-darwin",
      features ? [],
      extraModules ? [],
      enableHomeManager ? true,
    }: let
      darwinModules = lib.flatten (
        map (
          f:
            if builtins.isAttrs f && f ? darwin
            then f.darwin
            else if builtins.isAttrs f && (f ? homeManager || f ? nixos)
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

      hasHomeManager =
        if enableHomeManager != null
        then enableHomeManager
        else (homeManagerModules != []);
    in
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          outputs = config.flake;
          vars = config.flake.vars;
        };
        modules =
          darwinModules
          ++ (lib.optionals hasHomeManager [
            inputs.home-manager.darwinModules.home-manager
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
          ])
          ++ extraModules;
      };
  };
}
