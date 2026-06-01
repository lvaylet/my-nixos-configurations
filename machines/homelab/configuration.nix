{
  inputs,
  outputs,
  config,
  lib,
  ...
}: {
  networking.hostName = "homelab";

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.preservation.nixosModules.default

    # Hardware
    # ---
    ./hardware-configuration.nix
    ./disko.nix
    ./preservation.nix

    # Base Settings
    # ---
    ./../../modules/nixos/base.nix

    # Optional Features / Container Engine
    # ---
    ./../../modules/nixos/podman.nix

    # Programs / Services
    # ---
    ./../../modules/nixos/neovim.nix
    ./../../modules/nixos/nix-ld.nix
    ./../../modules/nixos/ssh.nix

    ./../../modules/nixos/adguardhome.nix
    ./../../modules/nixos/caddy.nix
    ./../../modules/nixos/cloudflare-tunnel.nix
    ./../../modules/nixos/couchdb.nix
    ./../../modules/nixos/filebrowser.nix
    ./../../modules/nixos/home-automation.nix
    ./../../modules/nixos/jellyfin.nix
    ./../../modules/nixos/media.nix
    ./../../modules/nixos/portainer.nix
    ./../../modules/nixos/qbittorrent.nix
  ];

  # Bootloader configuration
  # ---
  # Use the GRUB 2 boot loader, specifically optimized for our disko partitioning.
  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      limine.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
    };
  };

  # User group adjustments and root access
  # ---
  users.users.${config.vars.userName}.extraGroups = [
    "multimedia" # Let the user manage qBittorrent, Filebrowser and Jellyfin files/directories.
  ];

  # Allow `root` access over SSH from authorized hosts.
  users.users.root.openssh.authorizedKeys.keys =
    config.vars.sshPublicKeysPersonal
    ++ config.vars.sshPublicKeysWork;

  # Home Manager Configurations
  # ---
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};

    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      ${config.vars.userName} = {
        imports = [
          # Base Settings
          # ---
          ./../../modules/home-manager/base.nix

          # Programs / Services
          # ---
          ./../../modules/home-manager/bat.nix
          ./../../modules/home-manager/direnv.nix
          ./../../modules/home-manager/eza.nix
          ./../../modules/home-manager/git.nix
          ./../../modules/home-manager/jq.nix
          ./../../modules/home-manager/lazygit.nix
          ./../../modules/home-manager/nnn.nix
          ./../../modules/home-manager/ripgrep.nix
          ./../../modules/home-manager/starship.nix
          ./../../modules/home-manager/yazi.nix
        ];
      };
    };
  };
}
