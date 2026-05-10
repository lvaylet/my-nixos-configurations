_: {
  flake.homeModules.starship = _: {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };

    home.file.".config/starship.toml".source = ./dotfiles/starship.toml;
  };
}
