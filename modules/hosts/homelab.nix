{config, ...}: {
  flake.nixosConfigurations.homelab = config.flake.lib.mkHost {
    system = "x86_64-linux";

    # Hardware
    # ---
    hardware = ./_hardware/homelab.nix;

    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.git

      # Programs
      desktop.shell
      desktop.apps
      desktop.editors

      # Services
      services.network
      services.ssh
      services.adguardhome
      services.filebrowser
      services.home-automation
      services.jellyfin
      services.media
      services.qbittorrent
      services.ssd
    ];

    extraModules = [
      {
        networking.hostName = "homelab";
      }
    ];
  };
}
