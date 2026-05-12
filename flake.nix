{
  description = "My NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    vars = import ./vars.nix;

    systems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkNixOSConfig = path:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs vars;};
        modules = [path];
      };
  in {
    # All my NixOS Configurations
    # ---
    nixosConfigurations = {
      # Machines
      desktop-pc = mkNixOSConfig ./machines/desktop-pc/configuration.nix;
      homelab = mkNixOSConfig ./machines/homelab/configuration.nix;

      # Custom ISO
      iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs vars;};
        modules = [
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
          ./machines/iso/configuration.nix
        ];
      };
    };

    # Configure Git hooks.
    # Reference: https://github.com/cachix/git-hooks.nix
    # ---
    # Run the hooks in a sandbox with `nix flake check`.
    # Read-only filesystem and no internet access.
    checks = forAllSystems (system: {
      pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          # Check avauilable built-in hooks at:
          # https://github.com/cachix/git-hooks.nix#built-in-hooks

          # Nix
          alejandra.enable = true;
          deadnix.enable = true;
          flake-checker.enable = true;
          statix.enable = true;

          # Secret Detection
          pre-commit-hook-ensure-sops.enable = true;
          ripsecrets.enable = true;
          trufflehog.enable = true;

          # Misc
          check-added-large-files.enable = true;
          check-case-conflicts.enable = true;
          check-executables-have-shebangs.enable = true;
          check-shebang-scripts-are-executable.enable = true;
          detect-private-keys.enable = true;
          end-of-file-fixer.enable = true;
          fix-byte-order-marker.enable = true;
          mixed-line-endings.enable = true;
          trim-trailing-whitespace.enable = true;
        };
      };
    });

    # Configure formatter called by `nix fmt`, an alias for `nix formatter run`.
    # Reference: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-fmt.html
    # ---
    # formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra); # or .nixfmt-tree
    #
    # Alternatively, run the pre-commit hooks.
    formatter = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (self.checks.${system}.pre-commit-check) config;
        inherit (config) package configFile;
        script = ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        '';
      in
        pkgs.writeShellScriptBin "pre-commit-run" script
    );

    # Enter a development shell with `nix develop`.
    # The hooks will be installed automatically.
    # Or run pre-commit manually with `nix develop -c pre-commit run --all-files`.
    devShells = forAllSystems (system: {
      default = let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
      in
        pkgs.mkShell {
          inherit shellHook;
          buildInputs = enabledPackages;
        };
    });
  };
}
