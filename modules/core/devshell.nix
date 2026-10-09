{
  # Enter a development shell with `nix develop`.
  # The hooks will be installed automatically.
  # Or run pre-commit manually with `nix develop -c pre-commit run --all-files`.
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.checks.pre-commit-check) shellHook enabledPackages;
  in {
    devShells.default = pkgs.mkShell {
      inherit shellHook;
      buildInputs =
        enabledPackages
        ++ (with pkgs; [
          just
          nh
        ]);
    };
  };
}
