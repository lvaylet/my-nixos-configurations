{config, ...}: {
  flake.darwinConfigurations.macbook-air-m4-15 = config.flake.lib.mkDarwinHost {
    system = "aarch64-darwin";

    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.git
      core.neovim

      # Desktop & Shell
      desktop.apps
      desktop.editors
      desktop.fonts
      desktop.shell
      desktop.terminal

      # Services
      services.opencode
      services.ssh
    ];

    extraModules = [
      {
        networking.hostName = "macbook-air-m4-15";
      }
    ];
  };
}
