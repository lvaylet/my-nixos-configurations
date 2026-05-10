_: {
  flake.homeModules.lazygit = _: {
    programs.lazygit = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
