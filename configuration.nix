# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix = {
    settings = {
      # Enable Flakes and modern Nix.
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # For sudoless `cachix`.
      trusted-users = ["root" "laurent"];
    };

    # Garbage collection and store optimization.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    settings.auto-optimise-store = true;
  };

  # Allow unfree packages.
  nixpkgs.config.allowUnfree = true;

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
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # Recent kernel for recent GPU.
  };

  # Networking.
  networking.hostName = "desktop-pc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary.
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking.
  networking.networkmanager.enable = true;

  virtualisation = {
    vmware.host.enable = true; # VMware Workstation
    podman.enable = true; # A daemonless container engine for developing, managing, and running OCI Containers on your Linux System.
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
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

  # Enable OpenGL.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true; # Recommended for recent cards.

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  services = {
    xserver.videoDrivers = [
      "nvidia" # Configure Nvidia for GeForce RTX 5070 Ti. Load Nvidia drivers for Xorg and Wayland.
      "vmware" # Enable VMware video driver for better performance.
    ];
    # Enable the COSMIC Desktop Environment.
    desktopManager.cosmic.enable = true;
    displayManager = {
      cosmic-greeter.enable = true;
      # Enable automatic login (only with `cosmic-greeter` login manager).
      # Reference: https://wiki.nixos.org/wiki/COSMIC#Installation_(starting_with_NixOS_25.05)
      autoLogin = {
        enable = true;
        user = "laurent";
      };
    };
    # Slightly improve the performance by enabling system76's own scheduler.
    # References:
    # - https://wiki.nixos.org/wiki/COSMIC#Optimization
    # - https://github.com/pop-os/system76-scheduler
    system76-scheduler.enable = true;
  };

  # Configure keymap in X11.
  # FIXME Is this necessary/relevant/required for Wayland?
  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # Configure console keymap.
  console.keyMap = "us-acentos";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # When adding a new shell, always enable the shell system-wide, even if it's already enabled in your Home Manager configuration, otherwise it won't source the necessary files.
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
    # packages = with pkgs; [
    #   #  thunderbird
    # ];
    shell = pkgs.zsh;
  };

  # Install firefox.
  # programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # TODO Install packages like `just` and `pre-commit` in devShells
  # and use them only when necessary with `nix develop` ?
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.

    wget
    curl

    just # A command runner similar to Makefile, but simpler - https://github.com/casey/just

    git
    pre-commit # A framework for managing and maintaining multi-language pre-commit hooks - https://pre-commit.com/

    nvtopPackages.nvidia
  ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        statusline.lualine.enable = true; # Status line - https://github.com/nvim-lualine/lualine.nvim
        telescope.enable = true; # Fuzzy finder - https://github.com/nvim-telescope/telescope.nvim
        autocomplete.nvim-cmp.enable = true; # Completion plugin - https://github.com/hrsh7th/nvim-cmp
        filetree.nvimTree.enable = true; # File explorer - https://github.com/nvim-tree/nvim-tree.lua

        binds.whichKey.enable = true; # Show available keybindings in a popup as you type.

        lsp = {
          enable = true;
          formatOnSave = true;
        };

        languages = {
          enableTreesitter = true;

          nix = {
            enable = true;
            lsp = {
              enable = true;
              servers = ["nixd"];
            };
            format = {
              enable = true;
              type = ["alejandra"];
            };
            extraDiagnostics = {
              enable = true;
              types = ["statix" "deadnix"];
            };
          };
          typescript.enable = true;
          rust.enable = true;
        };
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
