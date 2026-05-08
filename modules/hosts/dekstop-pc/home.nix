# Module outputting a standalone home-manager configuration and a module for it. Module is also reused above in the configuration.
{
  self,
  inputs,
  ...
}: {
  # This is your standalone home-manager configuration, meant to be used on non-nixos machines
  # with the home-manager command
  flake.homeConfigurations.laurent = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    modules = [
      self.homeModules.laurent
      {
        home.username = "laurent";
        home.homeDirectory = "/home/laurent";
      }
    ];
  };

  # This is your home.nix, your module where you configure home-manager
  # It's imported both in standalone configuration above, and in your nixos configuration
  flake.homeModules.laurent = {pkgs, ...}: {
    home = {
      packages = with pkgs; [
        # Fonts
        # ---
        # Nerd Fonts - https://www.nerdfonts.com/
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg

        # Development
        # ---
        antigravity # Experience liftoff with the next-gen agent platform - https://antigravity.google/

        # Internet
        # ---
        google-chrome # Freeware web browser developed by Google - https://www.google.com/chrome/

        # Productivity
        # ---
        obsidian # Powerful knowledge base that works on top of a local folder of plain text Markdown files - https://obsidian.md/

        # Virtualization
        # ---
        vmware-workstation # Industry standard desktop hypervisor for x86-64 architecture - https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion

        # Nix
        # ---
        alejandra # An uncompromising Nix Code Formatter - https://github.com/kamadorueda/alejandra
        deadnix # Scan .nix files for dead code (unused variable bindings) - https://github.com/astro/deadnix
        nixd # A Nix Language Server, based on Nix libraries - https://github.com/nix-community/nixd
        nil # A Nix Language Server, an incremental analysis assistant for writing in Nix - https://github.com/oxalica/nil
        statix # Lints and suggestions for the Nix programming language - https://github.com/oppiliappan/statix
        nh # Yet another Nix CLI helper - https://github.com/nix-community/nh
        cachix # A service for Nix binary cache hosting - https://github.com/cachix/cachix
      ];

      # Home Manager is pretty good at managing dotfiles. The primary way to manage
      # plain files is through 'home.file'.
      file = {
        # Building this configuration will create a copy of 'dotfiles/screenrc' in
        # the Nix store. Activating the configuration will then make '~/.screenrc' a
        # symlink to the Nix store copy.
        # ".screenrc".source = dotfiles/screenrc;

        # You can also set the file content immediately.
        # ".gradle/gradle.properties".text = ''
        #   org.gradle.console=verbose
        #   org.gradle.daemon.idletimeout=3600000
        # '';

        ".config/starship.toml".source = ../../../dotfiles/starship.toml; # FIXME Make this a module too? Or inline it in Zsh configuration?

        # The configuration files below are not compatible with Yazi 0.3.3 (Nixpkgs 2024-09-04) installed by Home Manager. Use flakes instead to access the latest, bleeding edge version?
        # ".config/yazi/yazi.toml".source = dotfiles/yazi/yazi.toml;
        # ".config/yazi/keymap.toml".source = dotfiles/yazi/keymap.toml;
        # ".config/yazi/theme.toml".source = dotfiles/yazi/theme.toml;
      };

      # This value determines the Home Manager release that your configuration is
      # compatible with. This helps avoid breakage when a new Home Manager release
      # introduces backwards incompatible changes.
      #
      # You should not change this value, even if you update Home Manager. If you do
      # want to update the value, then make sure to first check the Home Manager
      # release notes.
      stateVersion = "26.05";
    };

    # Allow fontconfig to discover fonts and configurations installed through `home.packages` and `nix-env`.
    # Source: https://mynixos.com/home-manager/option/fonts.fontconfig.enable
    fonts.fontconfig.enable = true;

    programs = {
      bat.enable = true; # A cat(1) clone with wings - https://github.com/sharkdp/bat
      direnv = {
        # A shell extension that can load and unload environment variables depending on the current directory - https://direnv.net/
        enable = true;
        enableZshIntegration = true;
      };
      eza = {
        # A modern alternative to ls - https://github.com/eza-community/eza
        enable = true;
        enableZshIntegration = true;
      };
      fd.enable = true; # A simple, fast and user-friendly alternative to 'find' - https://github.com/sharkdp/fd
      fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      gemini-cli.enable = true;
      git = {
        enable = true;
        settings = {
          user = {
            name = "Laurent VAYLET";
            email = "laurent.vaylet@gmail.com";
          };
          init.defaultBranch = "main";

          # Popular Git Config Options - https://jvns.ca/blog/2024/02/16/popular-git-config-options/
          color.ui = "auto";
          commit.verbose = true;
          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            mnemonicPrefix = true;
            renames = true;
          };
          fetch.prune = true;
          help.autocorrect = 10;
          merge = {
            conflictstyle = "zdiff3";
            tool = "meld";
          };
          pull = {
            ff = "only";
            rebase = true;
          };
          push.autoSetupRemote = true;
          rebase = {
            autosquash = true;
            autostash = true;
          };
          rerere.enable = true;
          # url."git@github.com:".insteadOf = "https://github.com/"; # Be careful with this. Some repositories do not support cloning over SSH, for example https://github.com/oxalica/nil.
        };
      };
      jq.enable = true; # A lightweight and flexible command-line JSON processor - https://jqlang.github.io/jq/
      lazygit = {
        # A simple terminal UI for git commands - https://github.com/jesseduffield/lazygit
        enable = true;
        enableZshIntegration = true;
      };
      nnn.enable = true; # n³ The unorthodox terminal file manager - https://github.com/jarun/nnn
      pyenv = {
        # Simple Python version management - https://github.com/pyenv/pyenv
        enable = true;
        enableZshIntegration = true;
      };
      ripgrep.enable = true; # Recursively search directories for a regex pattern while respecting your gitignore - https://github.com/BurntSushi/ripgrep
      ssh = {
        enable = true;
        # Check options here: https://home-manager-options.extranix.com/?query=programs.ssh
        enableDefaultConfig = false;
        matchBlocks = {
          "rpi3" = {
            hostname = "192.168.1.68";
            user = "pi";
            identityFile = "~/.ssh/id_ed25519";
            checkHostIP = false; # = StrictHostKeyChecking No
          };
          "homelab-vm" = {
            hostname = "192.168.1.194";
            user = "core";
            identityFile = "~/.ssh/id_ed25519";
            checkHostIP = false; # = StrictHostKeyChecking No
          };
        };
      };
      starship = {
        # The minimal, blazing-fast, and infinitely customizable prompt for any shell! - https://starship.rs/guide/
        enable = true;
        enableZshIntegration = true;
      };
      vscode = {
        enable = true;
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            # Editor
            # ---
            vscodevim.vim # Vim Emulation

            # Linters and LSPs
            # ---
            davidanson.vscode-markdownlint # Markdown Linting and Style Checking

            # Themes and Icons
            # ---
            zhuangtongfa.material-theme # One Dark Pro - Atom's iconic One Dark theme for Visual Studio Code
            pkief.material-icon-theme # Material Icon Theme - Material Design Icons for Visual Studio Code
            # Catppuccin - https://catppuccin.com/
            catppuccin.catppuccin-vsc
            catppuccin.catppuccin-vsc-icons

            # Nix
            # ---
            jnoortheen.nix-ide # Nix IDE
            bbenoist.nix # Nix Language Support
            kamadorueda.alejandra # The Uncompromising Nix Code Formatter
          ];
          userSettings = {
            # This property will be used to generate `settings.json`:
            # https://code.visualstudio.com/docs/getstarted/settings#_settingsjson
            "editor.fontFamily" = "MesloLGM Nerd Font";
            "editor.fontLigatures" = true;
            "editor.lineNumbers" = "relative";
            "editor.fontSize" = 14;
            "editor.formatOnSave" = true;
            "editor.rulers" = [
              80
              88
              100
              120
            ];

            "diffEditor.codeLens" = true;
            "diffEditor.hideUnchangedRegions.enabled" = true;
            "diffEditor.ignoreTrimWhitespace" = false;

            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;

            "files.associations" = {
              "*.bu" = "yaml";
              "*.container" = "ini";
              "*.ign" = "json";
            };
            "files.autoSave" = "afterDelay";
            "files.insertFinalNewline" = true;
            "files.trimFinalNewlines" = true;

            "git.autofetch" = true;
            "git.confirmSync" = false;
            "git.suggestSmartCommit" = false;

            "terminal.integrated.fontFamily" = "MesloLGM Nerd Font";
            "terminal.integrated.fontLigatures.enabled" = true;
            "terminal.integrated.fontSize" = 12;
            "terminal.integrated.lineHeight" = 1.2;

            "window.menuBarVisibility" = "toggle";
            # Adjust zoom level. Each increment above 0 (e.g. 1) or below (e.g. -1) represents zooming 20% larger or
            # smaller. You can also enter decimals to adjust the zoom level with a finer granularity.
            "window.zoomLevel" = 1;

            "workbench.colorTheme" = "Catppuccin Macchiato";
            "workbench.iconTheme" = "catppuccin-macchiato";

            # Language Specific Editor Settings
            # ---
            # Source: https://code.visualstudio.com/docs/configure/settings#_language-specific-editor-settings

            # Nix
            # ---
            # Easiest Way To Write Nix | Code Editor Setup, by Vimjoyer
            # https://www.youtube.com/watch?v=M_zMoHlbZBY&t=262s
            # https://github.com/vimjoyer/nix-editor-setup-video?tab=readme-ov-file#vscode-nix-ide-setup
            "[nix]" = {
              "editor.tabSize" = 2;
              "editor.formatOnPaste" = true;
              "editor.formatOnSave" = true;
              "editor.formatOnType" = false;
            };
            "nix.enableLanguageServer" = true; # Enable LSP.
            "nix.serverPath" = "nixd"; # The path to the LSP server executable: "nil", "nixd", or ["executable", "argument1", ...]
            "nix.serverSettings" = {
              "nixd" = {
                "formatting.command" = ["alejandra"]; # nixfmt, nixpkgs-fmt, alejandra
              };
            };
          };
        };
      };
      yazi = {
        # 💥 Blazing fast terminal file manager written in Rust, based on async I/O - https://github.com/sxyazi/yazi
        enable = true;
        enableZshIntegration = true;
        package = pkgs.yazi;
        shellWrapperName = "y";
      };
      # zellij = { # A terminal workspace with batteries included - https://github.com/zellij-org/zellij
      #   enable = true;
      #   enableZshIntegration = true;
      # };
      zsh = {
        # An interactive login shell and a command interpreter for shell scripting - https://www.zsh.org/
        enable = true;
        autocd = true; # Automatically enter into a directory if typed directly into shell.
        defaultKeymap = "viins"; # The default base keymap to use. One of `emacs` (= `-e`), `vicmd` (= `-a`) or `viins` (= `-v`).
        zplug = {
          # 🌺 A next-generation plugin manager for zsh - https://github.com/zplug/zplug
          enable = true;
          plugins = [
            {name = "zsh-users/zsh-autosuggestions";}
            {name = "zsh-users/zsh-completions";}
            {name = "zsh-users/zsh-syntax-highlighting";}
            {
              name = "plugins/git";
              tags = ["from:oh-my-zsh"];
            }
            {name = "MichaelAquilina/zsh-you-should-use";}
            {
              name = "hlissner/zsh-autopair";
              tags = ["defer:2"];
            }
          ];
        };
        shellAliases = {
          c = "clear";
          x = "exit";
          r = "source ~/.zshrc";

          # `ls` / `eza`
          # See: https://www.avonture.be/blog/linux-eza/
          ls = "eza --group --group-directories-first --icons --header --time-style long-iso";
          ll = "eza --group --group-directories-first --icons --header --time-style long-iso --long";
          llt = "eza --group --group-directories-first --icons --header --time-style long-iso --long --tree";
          la = "eza --group --group-directories-first --icons --header --time-style long-iso --long --all";
          lat = "eza --group --group-directories-first --icons --header --time-style long-iso --long --all --tree";

          cat = "bat"; # A cat(1) clone with wings
          y = "yazi"; # 💥 Blazing fast terminal file manager written in Rust, based on async I/O

          take = "() { mkdir -p \"$1\"; cd \"$1\"; }"; # Create a directory tree and `cd` into it.

          # History
          h = "history -10"; # last 10 history commands
          hc = "history -c"; # clear history
          hh = "history | cut -c 8-";
          hg = "history | grep "; # + command to search for

          # Aliases
          ag = "alias | grep "; # + alias to search for

          # Utils
          b = "btop";
          d = "ncdu --exclude /mnt --color dark "; # + path

          # Home Manager
          # hms = "cd ~/.config/home-manager; git pull; home-manager switch; cd -";
        };
      };
    };
  };
}
