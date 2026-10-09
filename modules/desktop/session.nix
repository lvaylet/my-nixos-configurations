{
  flake.modules.desktop.session = {
    nixos = {pkgs, ...}: {
      # Enable the Niri scrollable-tiling Wayland compositor.
      # Reference: https://github.com/YaLTeR/niri
      # ---
      programs.niri.enable = true;

      # Configure Greetd display manager with Tuigreet session launcher.
      # Reference: https://github.com/apognu/tuigreet
      # ---
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
            user = "greeter";
          };
        };
      };
    };

    homeManager = {
      inputs,
      pkgs,
      ...
    }: {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Niri scrollable-tiling Wayland window manager user configuration.
      # Reference: https://github.com/YaLTeR/niri
      # ---
      xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl;

      # Noctalia native Wayland desktop shell user configuration.
      # Reference: https://github.com/noctalia-dev/noctalia
      # ---
      programs.noctalia = {
        enable = true;
        package = pkgs.noctalia;
        checkConfig = false;
        settings = ./dotfiles/noctalia.toml;
      };
    };
  };
}
