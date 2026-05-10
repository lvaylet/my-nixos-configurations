# Module declaring systems supported by your flake, and importing
# `flake-parts` modules, for example for Home Manager.
#
# Read more at: https://flake.parts/options/home-manager.html
{inputs, ...}: {
  imports = [
    inputs.home-manager.flakeModules.home-manager
    inputs.git-hooks.flakeModule # https://flake.parts/options/git-hooks-nix.html
  ];

  systems = [
    "x86_64-linux"
  ];

  perSystem = {
    pkgs,
    config,
    ...
  }: {
    # Configure formatter called by `nix fmt`, an alias for `nix formatter run`.
    # Reference: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-fmt.html
    # ---
    # formatter = pkgs.alejandra; # or pkgs.nixfmt-tree
    #
    # Alternatively, run the pre-commit hooks.
    # Reference: https://flake.parts/options/git-hooks-nix.html
    formatter = let
      inherit (config.pre-commit.settings) package configFile;
      script = ''
        ${pkgs.lib.getExe package} run --all-files --config ${configFile}
      '';
    in
      pkgs.writeShellScriptBin "pre-commit-run" script;

    # Run the hooks in a sandbox with `nix flake check`.
    # Read-only filesystem and no internet access.
    # Reference: https://flake.parts/options/git-hooks-nix.html
    pre-commit = {
      check.enable = true;
      settings = {
        src = ./.;
        hooks = {
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
    };

    # Enter a development shell with `nix develop`.
    # The hooks will be installed automatically.
    # Or run pre-commit manually with `nix develop -c pre-commit run --all-files`.
    # Reference: https://github.com/cachix/git-hooks.nix#flakes-support
    devShells.default = let
      inherit (config.pre-commit) shellHook;
    in
      pkgs.mkShell {
        inherit shellHook;
        buildInputs = config.pre-commit.settings.enabledPackages;
      };
  };
}
