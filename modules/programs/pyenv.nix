_: {
  flake.homeModules.pyenv = _: {
    programs.pyenv = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
