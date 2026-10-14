{
  flake.modules.desktop.apps = {
    nixos = {
      # Enable touchpad support (enabled default in most desktopManager).
      services.libinput.enable = true;
    };

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        google-chrome # Freeware web browser developed by Google - https://www.google.com/chrome/

        # Nix
        # ---
        alejandra # An uncompromising Nix Code Formatter - https://github.com/kamadorueda/alejandra
        deadnix # Scan .nix files for dead code (unused variable bindings) - https://github.com/astro/deadnix
        nixd # A Nix Language Server, based on Nix libraries - https://github.com/nix-community/nixd
        statix # Lints and suggestions for the Nix programming language - https://github.com/oppiliappan/statix
        nh # Yet another Nix CLI helper - https://github.com/nix-community/nh
        cachix # A service for Nix binary cache hosting - https://github.com/cachix/cachix

        # System & Partitioning Tools
        # ---
        efibootmgr
        gptfdisk
        parted
        tparted
        just
        just-lsp
      ];

      programs = {
        ghostty.enable = true;

        # Reference: https://mynixos.com/home-manager/options/programs.obsidian
        obsidian.enable = true;
        # TODO Create `my-obsidian-vault` and check it out from GitHub.

        direnv = {
          enable = true;
          nix-direnv.enable = true; # Enable a faster, persistent implementation of `use_nix` and `use_flake`, to replace the built-in one.
        };

        eza = {
          enable = true;
          enableFishIntegration = true;
        };

        bat.enable = true;
        fd.enable = true;

        fzf = {
          enable = true;
          enableFishIntegration = true;
        };

        jq.enable = true;
        ripgrep.enable = true;

        yazi = {
          enable = true;
          enableFishIntegration = true;
          package = pkgs.yazi;
        };

        nnn.enable = true;

        opencode = {
          enable = true;
          tui = {
            theme = "catppuccin-macchiato";
          };
        };

        pyenv.enable = true;
      };
    };
  };
}
