_: {
  flake.homeModules.direnv = _: {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
