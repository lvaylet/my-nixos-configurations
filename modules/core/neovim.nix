_: {
  flake.modules.core.neovim = {
    nixos = {
      pkgs,
      vars,
      ...
    }: {
      # Declarative LazyVim starter configuration symlink
      systemd.tmpfiles.rules = [
        "d /home/${vars.userName}/.config 0755 ${vars.userName} users -"
        "L+ /home/${vars.userName}/.config/nvim - - - - ${./dotfiles/nvim}"
      ];

      # Upstream LazyVim runtime dependencies
      # Reference: https://www.lazyvim.org/installation
      environment.systemPackages = with pkgs; [
        # Upstream requirements
        git
        gcc
        gnumake
        ripgrep
        fd
        tree-sitter

        # Archive and download utilities
        curl
        unzip
        gnutar
        gzip
      ];

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
      };
    };

    darwin = {pkgs, ...}: {
      # Upstream LazyVim runtime dependencies and editor for macOS
      environment = {
        systemPackages = with pkgs; [
          neovim
          git
          gcc
          gnumake
          ripgrep
          fd
          tree-sitter
          curl
          unzip
          gnutar
          gzip
        ];

        variables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };

        shellAliases = {
          vi = "nvim";
          vim = "nvim";
        };
      };
    };

    homeManager = {
      lib,
      pkgs,
      ...
    }:
      lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        xdg.configFile."nvim" = {
          source = ./dotfiles/nvim;
          recursive = true;
        };
      };
  };
}
