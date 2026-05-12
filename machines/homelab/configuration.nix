{
  inputs,
  outputs,
  vars,
  ...
}: {
  networking.hostName = "homelab";

  imports = [
    inputs.home-manager.nixosModules.home-manager

    # Hardware
    # ---
    ./hardware-configuration-dummy.nix
    # ./../../modules/nixos/intel.nix
    ./../../modules/nixos/ssd.nix

    # Base Settings
    # ---
    ./../../modules/nixos/base.nix

    # Optional Features
    # ---
    ./../../modules/nixos/network.nix

    # Programs / Services
    # ---
    ./../../modules/nixos/neovim.nix
    ./../../modules/nixos/ssh.nix

    # ./../../services/tailscale.nix
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars;};

    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      ${vars.userName} = {
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
          # ./../../modules/home-manager/ssh.nix
          ./../../modules/home-manager/starship.nix
          ./../../modules/home-manager/yazi.nix
        ];
      };
    };
  };
}
