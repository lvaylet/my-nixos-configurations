_: {
  flake.homeModules.fzf = _: {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
