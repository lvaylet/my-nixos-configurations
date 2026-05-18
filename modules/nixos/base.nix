{
  pkgs,
  vars,
  ...
}: {
  imports = [
    ./_packages.nix
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;

      limine = {
        # A modern, advanced, portable, multi-protocol bootloader and boot manager.
        # For additional Limine module configuration options, check:
        # https://search.nixos.org/options?channel=unstable&show=boot.loader.limine
        enable = true;

        maxGenerations = 5; # Maximum number of latest generations in the boot menu.

        # Prepend extra settings to `limine.conf`.
        # The config format can be found here:
        # https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md
        extraConfig = ''
          remember_last_entry: yes
        '';

        # Append extra entries to the end of `limine.conf`.
        #
        # For Windows 11, follow these instructions to copy the Windows bootloader to Limine's ESP
        # and avoid using `uuid()`: https://github.com/basecamp/omarchy/discussions/1604
        #
        # Reference: https://wiki.archlinux.org/title/Limine#Windows_entry_(UEFI)
        extraEntries = ''
          /Windows 11
            protocol: efi
            path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
        '';

        style.wallpapers = with pkgs.nixos-artwork.wallpapers; [
          # Check available wallpapers here:
          # - https://github.com/NixOS/nixos-artwork/tree/master/wallpapers
          # - https://mynixos.com/packages/nixos-artwork.wallpapers
          # and make sure to append `.gnomeFilePath` below:
          catppuccin-macchiato.gnomeFilePath
          mosaic-blue.gnomeFilePath
          nineish-catppuccin-macchiato.gnomeFilePath
          simple-dark-gray-bootloader.gnomeFilePath
          waterfall.gnomeFilePath
        ];
      };
    };
  };

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

  # Configure garbage collection and store optimization.
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nix.settings.auto-optimise-store = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    # If set to true, you are free to add new users and groups to the system with the ordinary useradd and groupadd
    # commands. On system activation, the existing contents of the /etc/passwd and /etc/group files will be merged with
    # the contents generated from the users.users and users.groups options. The initial password for a user will be
    # set according to users.users, but existing passwords will not be changed.
    # If set to false, the contents of the user and group files will simply be replaced on system activation. This also
    # holds for the user passwords; all changed passwords will be reset according to the users.users configuration on
    # activation.
    mutableUsers = false;

    users.${vars.userName} = {
      isNormalUser = true;
      description = vars.fullName;
      hashedPassword = "$6$ZDig7r9f3QdUBTzl$pczfwXi/dl49SDRoYAKIk9UU8Lw.FXRl4Ayn1Mhn/22V1vK7q3FIMCzZK55b.vNzPED/bQi1XwvnDFEHnCCK/."; # Generate with `mkpasswd -m sha-512 <password>`.      shell = pkgs.zsh; # Make sure to enable `programs.zsh` too!
      # TODO hashedPasswordFile = config.sops.secrets."user-password".path;
      extraGroups = [
        "networkmanager"
        "wheel" # Enable `sudo` for this user.
      ];
      openssh.authorizedKeys.keys = [
        vars.sshPublicKeyPersonal
        vars.sshPublicKeyWork
      ];
      shell = pkgs.zsh; # Make sure to enable `programs.zsh` too!
    };
  };

  # TODO Move to dedicated module?
  nix.settings.trusted-users = [
    "root"
    vars.userName # For sudoless `cachix`.
  ];

  # TODO Move to dedicated module, e.g. `networking.nix`?
  networking = {
    firewall.enable = true;
    networkmanager.enable = true;
  };

  # When adding a new shell, always enable the shell system-wide, even if it's already enabled in
  # your Home Manager configuration. Otherwise it won't source the necessary files.
  # Reference: https://wiki.nixos.org/wiki/Command_Shell
  programs.zsh.enable = true;

  # Let users of the wheel group run commands as super user (via sudo) without providing a password.
  security.sudo.wheelNeedsPassword = false;

  # Enable Flakes and modern Nix.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Internationalization (i18n)
  # ---
  # Set time zone.
  time.timeZone = "Europe/Paris";
  # Set internationalization (i18n) properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  # Configure keymap in X11.
  # FIXME Is this necessary/relevant/required for Wayland?
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };
  # Configure console keymap.
  console.keyMap = "us-acentos";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
