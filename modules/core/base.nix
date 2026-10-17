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
      ];

      # Shell aliases for systemd and journalctl
      environment.shellAliases = {
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

        # Git (Oh-My-Zsh style aliases)
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

      # Configure Fish shell and completions for aliases across all configurations
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          # Completions for systemctl and journalctl aliases
          complete -c sc -w systemctl
          complete -c scs -w "systemctl status"
          complete -c sc-status -w "systemctl status"
          complete -c scr -w "systemctl restart"
          complete -c sc-restart -w "systemctl restart"
          complete -c scl -w "systemctl reload"
          complete -c sc-reload -w "systemctl reload"
          complete -c sc-start -w "systemctl start"
          complete -c sc-stop -w "systemctl stop"
          complete -c sc-failed -w "systemctl --failed"
          complete -c jc -w journalctl
          complete -c jcb -w "journalctl -b"
          complete -c jce -w "journalctl -e"
          complete -c jcf -w "journalctl -f"
          complete -c jcu -w "journalctl -u"
          complete -c jcuf -w "journalctl -f -u"
          complete -c logs -w "journalctl -u"
          complete -c logsf -w "journalctl -f -u"

          # Completions for git aliases
          complete -c g -w git
          complete -c ga -w "git add"
          complete -c gaa -w "git add"
          complete -c gst -w "git status"
          complete -c gco -w "git checkout"
          complete -c gcb -w "git checkout -b"
          complete -c gsw -w "git switch"
          complete -c gswc -w "git switch -c"
          complete -c gc -w "git commit"
          complete -c gca -w "git commit"
          complete -c gd -w "git diff"
          complete -c gds -w "git diff"
          complete -c gl -w "git pull"
          complete -c gp -w "git push"
          complete -c gpf -w "git push"
          complete -c gb -w "git branch"
          complete -c gba -w "git branch"
          complete -c gbd -w "git branch"
          complete -c grb -w "git rebase"
          complete -c gm -w "git merge"
          complete -c grh -w "git reset"
          complete -c grhh -w "git reset"
          complete -c gsta -w "git stash apply"
          complete -c gstp -w "git stash pop"
        '';
      };

      # This value determines the NixOS release from which the default
      # settings for stateful data, like file locations and database versions
      # on your system were taken. It‘s perfectly fine and recommended to leave
      # this value at the release version of the first install of this system.
      # Before changing this value read the documentation for this option
      # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
      system.stateVersion = "26.05"; # Did you read the comment?
    };

    homeManager = {vars, ...}: {
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
