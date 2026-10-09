{
  # Configure formatter called by `nix fmt`, an alias for `nix formatter run`.
  # Reference: https://nix.dev/manual/nix/2.34/command-ref/new-cli/nix3-fmt.html
  # ---
  # Run the pre-commit hooks as the formatter.
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    inherit (config.checks.pre-commit-check.config) package configFile;
    script = ''
      ${pkgs.lib.getExe package} run --all-files --config ${configFile}
    '';
  in {
    formatter = pkgs.writeShellScriptBin "pre-commit-run" script;
  };
}
