{
  inputs,
  pkgs,
  ...
}: {
  # Noctalia native Wayland desktop shell user configuration.
  # Reference: https://github.com/noctalia-dev/noctalia
  # ---
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    package = pkgs.noctalia;
    checkConfig = false;
    settings = ./dotfiles/noctalia.toml;
  };
}
