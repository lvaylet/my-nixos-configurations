{
  flake.modules.core.base = {
    nixos = {
      pkgs,
      vars,
      ...
    }: {
      boot.loader = {
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

      # Allow unfree packages.
      nixpkgs.config.allowUnfree = true;

      # Configure garbage collection and store optimization.
      nix = {
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
        settings = {
          auto-optimise-store = true;
          trusted-users = [
            "root"
            vars.userName # For sudoless `cachix`.
          ];
          # Enable Flakes and modern Nix.
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

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
          hashedPassword = "$6$ZDig7r9f3QdUBTzl$pczfwXi/dl49SDRoYAKIk9UU8Lw.FXRl4Ayn1Mhn/22V1vK7q3FIMCzZK55b.vNzPED/bQi1XwvnDFEHnCCK/."; # Generate with `mkpasswd -m sha-512 <password>`.
          # TODO hashedPasswordFile = config.sops.secrets."user-password".path;
          extraGroups = [
            "networkmanager"
            "wheel" # Enable `sudo` for this user.
          ];
          openssh.authorizedKeys.keys = [
            vars.sshPublicKeyPersonal
            vars.sshPublicKeyWork
          ];
          shell = pkgs.fish; # Make sure to enable `programs.fish` too!
        };
      };

      # When adding a new shell, always enable the shell system-wide, even if it's already enabled in
      # your Home Manager configuration. Otherwise it won't source the necessary files.
      # Reference: https://wiki.nixos.org/wiki/Command_Shell
      programs.fish.enable = true;
      programs.zsh.enable = true;

      # Let users of the wheel group run commands as super user (via sudo) without providing a password.
      security.sudo.wheelNeedsPassword = false;

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

      # Base packages for every machine in my inventory.
      environment.systemPackages = with pkgs; [
        efibootmgr # Linux user-space application to modify the Intel Extensible Firmware Interface (EFI) Boot Manager

        gptfdisk # Set of text-mode partitioning tools for Globally Unique Identifier (GUID) Partition Table (GPT) disks
        parted # Create, destroy, resize, check, and copy partitions
        tparted # Text-based user interface (TUI) frontend for parted

        git # Distributed version control system

        just # Handy way to save and run project-specific commands
        just-lsp # Language server for just

        vim # Most popular clone of the VI editor

        wget # Tool for retrieving files using HTTP, HTTPS, and FTP
        curl # Command line tool for transferring files with URL syntax
      ];

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "26.05"; # Did you read the comment?
    };

    homeManager = {
      pkgs,
      vars,
      ...
    }: {
      home = {
        username = vars.userName;
        homeDirectory = "/home/${vars.userName}";

        # This value determines the Home Manager release that your configuration is
        # compatible with. This helps avoid breakage when a new Home Manager release
        # introduces backwards incompatible changes.
        #
        # You should not change this value, even if you update Home Manager. If you do
        # want to update the value, then make sure to first check the Home Manager
        # release notes.
        stateVersion = "26.05";

        packages = with pkgs; [
          # Internet
          # ---
          google-chrome # Freeware web browser developed by Google - https://www.google.com/chrome/

          # Nix
          # ---
          alejandra # An uncompromising Nix Code Formatter - https://github.com/kamadorueda/alejandra
          deadnix # Scan .nix files for dead code (unused variable bindings) - https://github.com/astro/deadnix
          nixd # A Nix Language Server, based on Nix libraries - https://github.com/nix-community/nixd
          statix # Lints and suggestions for the Nix programming language - https://github.com/oppiliappan/statix
          nh # Yet another Nix CLI helper - https://github.com/nix-community/nh
          cachix # A service for Nix binary cache hosting - https://github.com/cachix/cachix
        ];
      };

      # Whether new or changed services that are wanted by active targets should be started.
      # Additionally, stop obsolete services from the previous generation.
      # The alternatives are
      # - `suggest` (or `false`) : Use a very simple shell script to print suggested `systemctl`
      #   commands to run. You will have to manually run those commands after the switch.
      # - `sd-switch` (or `true`) : Use `sd-switch`, a tool that determines the necessary changes and
      #   automatically apply them.
      systemd.user.startServices = "sd-switch";
    };
  };
}
