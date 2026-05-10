_: {
  flake.homeModules.yazi = {pkgs, ...}: {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.yazi;
      shellWrapperName = "y";
    };
  };
}
