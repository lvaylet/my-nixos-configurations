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
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white' --cmd niri-session";
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

      # Wallpapers directory versioned in the repository.
      # ---
      home.file."Pictures/wallpapers".source = ../../assets/wallpapers;

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
