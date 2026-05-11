# Module outputting a nixos system and a configuration module for it.
{self, ...}: {
  # This is your configuration.nix, a place where you configure your system
  # You can place it in a separate file.
  flake.nixosModules.desktopPcConfiguration = {pkgs, ...}: {
    imports = [
      self.nixosModules.desktopPcHardware
      self.nixosModules.cosmic
      self.nixosModules.flakes
      self.nixosModules.garbageCollection
      self.nixosModules.i18n
      self.nixosModules.keyboardUS
      self.nixosModules.neovim
      self.nixosModules.nvidia
      self.nixosModules.podman
      self.nixosModules.printing
      self.nixosModules.sound
      self.nixosModules.ssh
      self.nixosModules.unfreePackages
      self.nixosModules.vmwareWorkstation
    ];

    # TODO Move to a feature in a dedicated module?
    nix = {
      settings = {
        trusted-users = [
          "root"
          "laurent" # For sudoless `cachix`.
        ];
      };
    };

    # Bootloader and kernel.
    boot = {
      loader = {
        limine = {
          # A modern, advanced, portable, multi-protocol bootloader and boot manager.
          # For additional Limine module configuration options, refer to https://search.nixos.org/options?channel=unstable&show=boot.loader.limine.
          enable = true;
          maxGenerations = 5; # Maximum number of latest generations in the boot menu.
          # Prepend extra settings to `limine.conf`.
          # The config format can be found here: https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md
          extraConfig = ''
            remember_last_entry: yes
          '';
          # Append extra entries to the end of `limine.conf`.
          #
          # For Windows 11, follow these instructions to copy the Windows bootloader to Limine's ESP
          # and avoid using uuid(): https://github.com/basecamp/omarchy/discussions/1604
          #
          # Reference: https://wiki.archlinux.org/title/Limine#Windows_entry_(UEFI)
          extraEntries = ''
            /Windows 11
              protocol: efi
              path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
          '';
          style.wallpapers = [
            # Check available wallpapers here:
            # - https://github.com/NixOS/nixos-artwork/tree/master/wallpapers
            # - https://mynixos.com/packages/nixos-artwork.wallpapers
            # and make sure to append `.gnomeFilePath` below:
            pkgs.nixos-artwork.wallpapers.simple-dark-gray-bootloader.gnomeFilePath
            pkgs.nixos-artwork.wallpapers.catppuccin-macchiato.gnomeFilePath
            pkgs.nixos-artwork.wallpapers.nineish-catppuccin-macchiato.gnomeFilePath
            pkgs.nixos-artwork.wallpapers.mosaic-blue.gnomeFilePath
          ];
        };
        efi.canTouchEfiVariables = true;
      };
    };

    # Networking
    # ---
    networking.hostName = "desktop-pc"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via `wpa_supplicant`.

    # Configure network proxy if necessary.
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable network.
    networking.networkmanager.enable = true;

    # System Packages
    # ---
    # TODO Install packages like `just` and `pre-commit` in devShells and use them ad-hoc with `nix develop`?
    environment.systemPackages = with pkgs; [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

      wget
      curl

      just # A command runner similar to Makefile, but simpler - https://github.com/casey/just

      git
      pre-commit # A framework for managing and maintaining multi-language pre-commit hooks - https://pre-commit.com/
    ];

    # When adding a new shell, always enable the shell system-wide, even if it's already enabled in your Home Manager
    # configuration, otherwise it won't source the necessary files.
    # Reference: https://wiki.nixos.org/wiki/Command_Shell
    programs.zsh.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.laurent = {
      isNormalUser = true;
      description = "Laurent VAYLET";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      shell = pkgs.zsh;
    };
    home-manager.users.laurent = self.homeModules.laurent;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "26.05"; # Did you read the comment?
  };
}
