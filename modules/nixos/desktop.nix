{pkgs, ...}: {
  # Enable the Niri scrollable-tiling Wayland compositor.
  # Reference: https://github.com/YaLTeR/niri
  # ---
  programs.niri.enable = true;

  # Enable the Fish shell system-wide for completions and /etc/shells registration.
  # ---
  programs.fish.enable = true;

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
}
