{config, ...}: {
  flake.nixosConfigurations.desktop-pc = config.flake.lib.mkHost {
    system = "x86_64-linux";

    # Hardware
    # ---
    hardware = ./_hardware/desktop-pc.nix;

    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.git

      # Desktop & Shell
      desktop.session
      desktop.terminal
      desktop.shell
      desktop.fonts
      desktop.editors
      desktop.audio
      desktop.graphics
      desktop.apps

      # Services
      services.network
      services.ssh
      services.podman
      services.printing
      services.ssd
    ];

    extraModules = [
      {
        networking.hostName = "desktop-pc";
      }
    ];
  };
}
