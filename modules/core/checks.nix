{inputs, ...}: {
  # Configure Git hooks.
  # Reference: https://github.com/cachix/git-hooks.nix
  # ---
  # Run the hooks in a sandbox with `nix flake check`.
  # Read-only filesystem and no internet access.
  perSystem = {system, ...}: {
    checks = {
      pre-commit-check = inputs.git-hooks.lib.${system}.run {
        src = ./../..;
        hooks = {
          # Check available built-in hooks at:
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
  };
}
