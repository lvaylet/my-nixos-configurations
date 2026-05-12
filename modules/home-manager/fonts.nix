{pkgs, ...}: {
  home.packages = with pkgs; [
    # Nerd Fonts - https://www.nerdfonts.com/
    # ---
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
  ];

  # Allow fontconfig to discover fonts and configurations installed through `home.packages` and `nix-env`.
  # Source: https://mynixos.com/home-manager/option/fonts.fontconfig.enable
  fonts.fontconfig.enable = true;
}
