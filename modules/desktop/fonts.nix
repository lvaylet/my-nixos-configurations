{
  flake.modules.desktop.fonts = {
    darwin = {pkgs, ...}: {
      fonts.packages = with pkgs; [
        # Nerd Fonts for macOS (installed into /Library/Fonts/Nix Fonts)
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
      ];
    };

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        # Nerd Fonts - https://www.nerdfonts.com/
        # ---
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
      ];

      # Allow fontconfig to discover fonts and configurations installed through `home.packages` and `nix-env`,
      # and prioritize FiraCode Nerd Font whenever a generic `monospace` font is requested.
      # Source: https://mynixos.com/home-manager/options/fonts.fontconfig
      fonts.fontconfig = {
        enable = pkgs.stdenv.hostPlatform.isLinux;
        defaultFonts = {
          monospace = [
            "FiraCode Nerd Font"
            "FiraCode Nerd Font Mono"
          ];
        };
      };
    };
  };
}
