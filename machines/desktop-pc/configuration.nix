{
  inputs,
  outputs,
  vars,
  ...
}: {
  networking.hostName = "desktop-pc";

  imports = [
    inputs.home-manager.nixosModules.home-manager

    # Hardware
    # ---
    ./hardware-configuration.nix
    # ./../../modules/nixos/amd.nix
    ./../../modules/nixos/ssd.nix

    # Base Settings
    # ---
    ./../../modules/nixos/base.nix

    # Optional Features
    # ---
    ./../../modules/nixos/desktop.nix
    ./../../modules/nixos/network.nix

    # Programs / Services
    # ---
    ./../../modules/nixos/neovim.nix
    ./../../modules/nixos/nvidia.nix
    ./../../modules/nixos/podman.nix
    ./../../modules/nixos/printing.nix
    ./../../modules/nixos/sound.nix
    ./../../modules/nixos/ssh.nix
    ./../../modules/nixos/vmware-workstation.nix

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
          ./../../modules/home-manager/fd.nix
          ./../../modules/home-manager/fzf.nix
          ./../../modules/home-manager/gemini-cli.nix
          ./../../modules/home-manager/ghostty.nix
          ./../../modules/home-manager/git.nix
          ./../../modules/home-manager/jq.nix
          ./../../modules/home-manager/lazygit.nix
          ./../../modules/home-manager/nnn.nix
          ./../../modules/home-manager/obsidian.nix
          # ./../../modules/home-manager/pyenv.nix
          ./../../modules/home-manager/ripgrep.nix
          # ./../../modules/home-manager/ssh.nix
          ./../../modules/home-manager/starship.nix
          ./../../modules/home-manager/vscode.nix
          ./../../modules/home-manager/yazi.nix
          ./../../modules/home-manager/zed-editor.nix
        ];
      };
    };
  };
}
