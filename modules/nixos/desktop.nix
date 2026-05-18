_: {
  # Enable the COSMIC Desktop Environment.
  # ---
  services = {
    desktopManager.cosmic.enable = true;
    displayManager = {
      cosmic-greeter.enable = true;

      # Enable automatic login (only with `cosmic-greeter` login manager).
      # Reference: https://wiki.nixos.org/wiki/COSMIC#Installation_(starting_with_NixOS_25.05)
      # FIXME Figure out how to unlock the user's default keyring too (required by Google Chrome).
      # autoLogin = {
      #   enable = true;
      #   user = vars.userName;
      # };
    };

    # Slightly improve the performance by enabling system76's own scheduler.
    # References:
    # - https://wiki.nixos.org/wiki/COSMIC#Optimization
    # - https://github.com/pop-os/system76-scheduler
    system76-scheduler.enable = true;
  };
}
