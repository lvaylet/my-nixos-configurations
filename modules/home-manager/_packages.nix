{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  # Reference: https://discourse.nixos.org/t/how-to-use-hostname-in-a-path/42612/3
  isServer = lib.hasPrefix "svr" osConfig.networking.hostName;
in {
  home = {
    packages = with pkgs;
      [
        # Development
        # ---
        antigravity # Experience liftoff with the next-gen agent platform - https://antigravity.google/

        # Internet
        # ---
        google-chrome # Freeware web browser developed by Google - https://www.google.com/chrome/

        # Nix
        # ---
        alejandra # An uncompromising Nix Code Formatter - https://github.com/kamadorueda/alejandra
        deadnix # Scan .nix files for dead code (unused variable bindings) - https://github.com/astro/deadnix
        nixd # A Nix Language Server, based on Nix libraries - https://github.com/nix-community/nixd
        statix # Lints and suggestions for the Nix programming language - https://github.com/oppiliappan/statix
        nh # Yet another Nix CLI helper - https://github.com/nix-community/nh
        cachix # A service for Nix binary cache hosting - https://github.com/cachix/cachix
      ]
      ++ (
        if isServer
        then [
          # Below packages are for servers only == excluded from personal machines.
        ]
        else [
          # Below packages are for personal machines only == excluded from servers.
        ]
      );
  };
}
