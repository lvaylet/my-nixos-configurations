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
      core.preservation

      # Services
      services.network
      services.ssh
      services.podman
      services.media
      services.filebrowser
      services.home-automation
      services.portainer
      services.jellyfin
      services.qbittorrent
      services.nix-ld
      services.ssd
    ];

    extraModules = [
      ({pkgs, ...}: {
        networking.hostName = "homelab";

        # Use the GRUB 2 boot loader.
        boot.loader = {
          limine.enable = lib.mkForce false;
          efi.canTouchEfiVariables = lib.mkForce false;
          grub = {
            enable = true;
            efiSupport = true;
            efiInstallAsRemovable = true;
            # devices = [ ]; # no need to set devices, disko will add all devices that have a EF02 partition to the list already
            # device = "/dev/sda"; # or "nodev" for efi only
          };
          # boot.loader.efi.efiSysMountPoint = "/boot/efi";
        };

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
