let
  # Shell shortcuts for systemd and journalctl (NixOS)
  systemdAliases = {
    # systemctl management
    sc = "systemctl";
    sc-status = "systemctl status";
    sc-restart = "systemctl restart";
    sc-reload = "systemctl reload";
    sc-start = "systemctl start";
    sc-stop = "systemctl stop";
    sc-failed = "systemctl --failed";

    # Shorthand aliases
    scs = "systemctl status";
    scr = "systemctl restart";
    scl = "systemctl reload";

    # journalctl logging
    jc = "journalctl";
    jcb = "journalctl -b"; # Current boot
    jce = "journalctl -e"; # End of journal
    jcf = "journalctl -f"; # Follow journal
    jcu = "journalctl -u"; # Unit logs, e.g.: jcu jellyfin
    jcuf = "journalctl -f -u"; # Follow unit logs, e.g.: jcuf jellyfin
    logs = "journalctl -u"; # Unit logs, e.g.: logs jellyfin
    logsf = "journalctl -f -u"; # Follow unit logs, e.g.: logsf jellyfin
  };

  # Git (Oh-My-Zsh style shortcuts shared across NixOS and Darwin)
  gitAliases = {
    g = "git";
    ga = "git add";
    gaa = "git add --all";
    gst = "git status";
    gco = "git checkout";
    gcb = "git checkout -b";
    gsw = "git switch";
    gswc = "git switch -c";
    gc = "git commit --verbose";
    gcm = "git commit --message";
    gca = "git commit --verbose --all";
    gcam = "git commit --all --message";
    "gc!" = "git commit --verbose --amend";
    "gca!" = "git commit --verbose --all --amend";
    "gcan!" = "git commit --verbose --all --no-edit --amend";
    gd = "git diff";
    gds = "git diff --staged";
    gl = "git pull";
    gp = "git push";
    gpf = "git push --force-with-lease";
    gb = "git branch";
    gba = "git branch --all";
    gbd = "git branch --delete";
    glo = "git log --oneline --decorate";
    glg = "git log --stat";
    glp = "git log --patch";
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase --interactive";
    gm = "git merge";
    gma = "git merge --abort";
    gmc = "git merge --continue";
    gsta = "git stash apply";
    gstp = "git stash pop";
    gsts = "git stash show --patch";
    gstd = "git stash drop";
    grh = "git reset";
    grhh = "git reset --hard";
    gclean = "git clean --interactive -d";
  };
in {
  flake.modules.core.base = {
    nixos = {
      pkgs,
      vars,
      ...
    }: {
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
          openssh.authorizedKeys.keys =
            [
              vars.sshPublicKeyPersonal
            ]
            ++ vars.sshPublicKeysWork;
          shell = pkgs.fish;
        };
      };

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

      # List packages installed in system profile.
      # You can use https://search.nixos.org/ to find more packages (and options).
      environment.systemPackages = with pkgs; [
        curl
        gh
        git
        htop
        wget

        # Nix Development & Deployment Stack
        alejandra
        cachix
        deadnix
        just
        just-lsp
        nh
        nixd
        statix
      ];

      # Shell aliases for systemd, journalctl, and Git (available in Bash and non-Fish shells)
      environment.shellAliases = systemdAliases // gitAliases;

      # Configure Direnv (with nix-direnv) and Fish shell with native abbreviations
      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        fish = {
          enable = true;
          shellAbbrs = systemdAliases // gitAliases;
        };
      };

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "26.05"; # Did you read the comment?
    };

    homeManager = {
      lib,
      pkgs,
      vars,
      ...
    }: {
      home = {
        username = vars.userName;
        homeDirectory =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "/Users/${vars.userName}"
          else "/home/${vars.userName}";

        # This value determines the Home Manager release that your configuration is
        # compatible with. This helps avoid breakage when a new Home Manager release
        # introduces backwards incompatible changes.
        #
        # You should not change this value, even if you update Home Manager. If you do
        # want to update the value, then make sure to first check the Home Manager
        # release notes.
        stateVersion = "26.05";
      };

      # Whether new or changed services that are wanted by active targets should be started.
      # Additionally, stop obsolete services from the previous generation.
      systemd.user.startServices = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "sd-switch";
    };

    darwin = {
      pkgs,
      vars,
      ...
    }: {
      # Allow unfree packages.
      nixpkgs.config.allowUnfree = true;

      # Disable nix-darwin's management of the Nix installation: on this host
      # the Nix installation is managed by the Determinate Nix Installer, which
      # runs its own daemon and conflicts with nix-darwin's native Nix
      # management. See the `nix.enable` option documentation for details.
      nix.enable = false;

      # Configure garbage collection and store settings.
      # Note: `nix.gc.automatic` requires `nix.enable`, which is now disabled;
      # garbage collection is handled by the Determinate Nix daemon instead.
      nix = {
        gc = {
          automatic = false;
          interval = {
            Weekday = 0;
            Hour = 0;
            Minute = 0;
          };
          options = "--delete-older-than 7d";
        };
        settings = {
          trusted-users = [
            "root"
            vars.userName
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      # Define user account for Darwin.
      users.users.${vars.userName} = {
        home = "/Users/${vars.userName}";
        description = vars.fullName;
        shell = pkgs.fish;
      };

      # Enable Touch ID for sudo authentication.
      security.pam.services.sudo_local.touchIdAuth = true;

      # System packages.
      environment.systemPackages = with pkgs; [
        curl
        gh
        git
        htop
        wget

        # Nix Development & Deployment Stack
        alejandra
        cachix
        deadnix
        just
        just-lsp
        nh
        nixd
        statix
      ];

      # Shell aliases for Git (available in Bash and non-Fish shells).
      environment.shellAliases = gitAliases;

      # Enable Direnv (with nix-direnv) and Fish shell with native Git abbreviations on Darwin.
      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
        fish = {
          enable = true;
          shellAbbrs = gitAliases;
        };
      };

      # System state version for nix-darwin.
      system.stateVersion = 6;
    };
  };
}
