{
  config,
  lib,
  ...
}: {
  flake.nixosConfigurations.homelab = config.flake.lib.mkHost {
    system = "x86_64-linux";
    enableHomeManager = false;

    # Hardware
    # ---
    hardware = ./_hardware/homelab.nix;

    # Enabled Features
    # ---
    features = with config.flake.modules; [
      # Base Settings
      core.base
      core.grub
      core.neovim
      core.preservation

      # Services
      services.caddy
      services.filebrowser
      services.home-automation
      services.jellyfin
      services.media
      services.n8n
      services.network
      services.nix-ld
      services.opencode
      services.podman
      services.portainer
      services.qbittorrent
      services.ssd
      services.ssh
      services.tailscale
      services.uptime-kuma
      services.waha
    ];

    extraModules = [
      ({pkgs, ...}: {
        networking.hostName = "homelab";

        # Define user packages as in the source repository.
        users.users.${config.flake.vars.userName}.packages = with pkgs; [
          tree
        ];

        # Allow `root` access over SSH from authorized hosts.
        services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
        users.users.root.openssh.authorizedKeys.keys =
          [
            config.flake.vars.sshPublicKeyPersonal
          ]
          ++ config.flake.vars.sshPublicKeysWork;
      })
    ];
  };
}
