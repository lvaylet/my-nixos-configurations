_: {
  flake.homeModules.eza = _: {
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
