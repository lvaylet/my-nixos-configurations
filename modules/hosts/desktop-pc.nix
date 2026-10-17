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
      core.neovim

      # Desktop & Shell
      desktop.apps
      desktop.audio
      desktop.editors
      desktop.fonts
      desktop.graphics
      desktop.session
      desktop.shell
      desktop.terminal

      # Services
      services.bluetooth
      services.network
      services.nix-ld
      services.podman
      services.printing
      services.ssd
      services.ssh
      services.tailscale
    ];

    extraModules = [
      {
        networking.hostName = "desktop-pc";
      }
    ];
  };
}
