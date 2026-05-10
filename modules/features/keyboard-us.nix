_: {
  flake.nixosModules.keyboardUS = {
    # Configure keymap in X11.
    # FIXME Is this necessary/relevant/required for Wayland?
    services.xserver.xkb = {
      layout = "us";
      variant = "intl";
    };

    # Configure console keymap.
    console.keyMap = "us-acentos";
  };
}
