{
  flake.modules.core.neovim = {
    homeManager = {pkgs, ...}: {
      # Declarative LazyVim starter configuration symlink
      xdg.configFile."nvim".source = ./dotfiles/nvim;

      # Upstream LazyVim runtime dependencies
      # Reference: https://www.lazyvim.org/installation
      home.packages = with pkgs; [
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
  };
}
