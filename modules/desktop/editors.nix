{
  flake.modules.desktop.editors = {
    homeManager = {pkgs, ...}: {
      # Declarative LazyVim starter configuration symlink
      xdg.configFile."nvim".source = ./dotfiles/nvim;

      # Upstream LazyVim runtime dependencies
      # Reference: https://www.lazyvim.org/installation
      home.packages = with pkgs; [
        # Upstream requirements
        git
        gcc
        gnumake
        ripgrep
        fd

        # Archive and download utilities
        curl
        unzip
        gnutar
        gzip

        # Wayland clipboard integration for Niri
        wl-clipboard
      ];

      programs = {
        neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
          withPython3 = true;
        };

        vscode = {
          enable = true;
          profiles.default = {
            extensions = with pkgs.vscode-extensions; [
              # Linters and LSPs
              # ---
              davidanson.vscode-markdownlint # Markdown Linting and Style Checking

              # Themes and Icons
              # ---
              arcticicestudio.nord-visual-studio-code

              # Languages
              # ---
              # Nix
              jnoortheen.nix-ide # Nix IDE
              bbenoist.nix # Nix Language Support
              kamadorueda.alejandra # The Uncompromising Nix Code Formatter
              # TOML
              tamasfe.even-better-toml # Fully-featured TOML support
            ];
            userSettings = {
              # This property will be used to generate `settings.json`:
              # https://code.visualstudio.com/docs/getstarted/settings#_settingsjson
              "editor.fontFamily" = "FiraCode Nerd Font";
              "editor.fontLigatures" = true;
              "editor.lineNumbers" = "relative";
              "editor.fontSize" = 12;
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

              "terminal.integrated.fontFamily" = "FiraCode Nerd Font";
              "terminal.integrated.fontLigatures.enabled" = true;
              "terminal.integrated.fontSize" = 12;
              "terminal.integrated.lineHeight" = 1.2;

              "window.menuBarVisibility" = "toggle";
              "window.zoomLevel" = 1;

              "workbench.colorTheme" = "Nord";

              # Language Specific Editor Settings
              # ---
              # Source: https://code.visualstudio.com/docs/configure/settings#_language-specific-editor-settings
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

        zed-editor = {
          enable = true;

          # This populates auto_install_extensions` in User Settings.
          extensions = [
            # Themes and Icon Themes
            # ---
            "one-dark-pro"
            "material-icon-theme"

            # Languages
            # ---
            "nix"
            "toml"
          ];

          # Everything inside of these brackets are Zed options.
          # Reference: https://wiki.nixos.org/wiki/Zed
          userSettings = {
            theme = {
              mode = "system";
              light = "One Light";
              dark = "One Dark";
            };
            iconTheme = "Material Icon Theme";

            hour_format = "hour24";

            auto_update = false;

            vim_mode = true;

            # Tell Zed to use `direnv`, and `direnv` can use a `flake.nix` environment.
            load_direnv = "shell_hook";

            lsp = {
              nix = {
                binary = {
                  path_lookup = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
