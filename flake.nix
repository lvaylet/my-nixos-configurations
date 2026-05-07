{
  description = "My NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic Pattern
    # ---
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # wrapper-modules.url = "github:Birdeehub/nix-wrapper-modules";

    # Manage Neovim with `nvf`.
    # References:
    # - https://www.youtube.com/watch?v=uP9jDrRvAwM
    # - https://nvf.notashelf.dev/#sec-nixos-flakes-usage
    # - https://www.youtube.com/watch?v=VTIGSxpzlIM
    nvf = {
      url = "github:NotAShelf/nvf";
      # You can override the input nixpkgs to follow your system's
      # instance of nixpkgs. This is safe to do as nvf does not depend
      # on a binary cache.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Seamless integration of Git hooks with Nix.
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {inherit inputs;}
    (inputs.import-tree ./modules);

  # outputs = {
  #   self,
  #   nixpkgs,
  #   home-manager,
  #   nvf,
  #   ...
  # } @ inputs: let
  #   forEachSystem = nixpkgs.lib.genAttrs ["x86_64-linux"];
  # in {
  #   nixosConfigurations = {
  #     desktop-pc = nixpkgs.lib.nixosSystem {
  #       specialArgs = {inherit inputs;};
  #       modules = [
  #         ./configuration.nix

  #         home-manager.nixosModules.home-manager
  #         {
  #           home-manager = {
  #             useGlobalPkgs = true;
  #             useUserPackages = true;
  #             users.laurent = import ./home.nix;
  #           };
  #         }

  #         nvf.nixosModules.default
  #       ];
  #     };
  #   };

  #   # Run the hooks with `nix fmt`.
  #   formatter = forEachSystem (
  #     system: let
  #       pkgs = nixpkgs.legacyPackages.${system};
  #       inherit (self.checks.${system}.pre-commit-check) config;
  #       inherit (config) package configFile;
  #       script = ''
  #         ${pkgs.lib.getExe package} run --all-files --config ${configFile}
  #       '';
  #     in
  #       pkgs.writeShellScriptBin "pre-commit-run" script
  #   );

  #   # Run the hooks in a sandbox with `nix flake check`.
  #   # Read-only filesystem and no internet access.
  #   checks = forEachSystem (system: {
  #     pre-commit-check = inputs.git-hooks.lib.${system}.run {
  #       src = ./.;
  #       hooks = {
  #         # https://github.com/cachix/git-hooks.nix#built-in-hooks

  #         # Nix
  #         alejandra.enable = true;
  #         deadnix.enable = true;
  #         flake-checker.enable = true;
  #         statix.enable = true;

  #         # Secret Detection
  #         pre-commit-hook-ensure-sops.enable = true;
  #         ripsecrets.enable = true;
  #         trufflehog.enable = true;

  #         # Misc
  #         check-added-large-files.enable = true;
  #         check-case-conflicts.enable = true;
  #         check-executables-have-shebangs.enable = true;
  #         check-shebang-scripts-are-executable.enable = true;
  #         detect-private-keys.enable = true;
  #         end-of-file-fixer.enable = true;
  #         fix-byte-order-marker.enable = true;
  #         mixed-line-endings.enable = true;
  #         trim-trailing-whitespace.enable = true;
  #       };
  #     };
  #   });

  #   # Enter a development shell with `nix develop`.
  #   # The hooks will be installed automatically.
  #   # Or run pre-commit manually with `nix develop -c pre-commit run --all-files`
  #   devShells = forEachSystem (system: {
  #     default = let
  #       pkgs = nixpkgs.legacyPackages.${system};
  #       inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
  #     in
  #       pkgs.mkShell {
  #         inherit shellHook;
  #         buildInputs = enabledPackages;
  #       };
  #   });
  # };
}
