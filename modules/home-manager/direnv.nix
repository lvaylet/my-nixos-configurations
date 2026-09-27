_: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # Enable a faster, persistent implementation of `use_nix` and `use_flake`, to replace the built-in one.
  };
}
