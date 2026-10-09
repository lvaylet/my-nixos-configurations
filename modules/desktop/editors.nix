{
  flake.modules.desktop.editors = {
    nixos = {inputs, ...}: {
      # Import nvf NixOS module to get access to `programs.nvf` below.
      # Reference: https://nvf.notashelf.dev/#sec-nixos-flakes-usage
      imports = [
        inputs.nvf.nixosModules.default
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

            luaConfigPost = ''
              -- Configure FiraCode Nerd Font with ligatures for GUI frontends.
              vim.opt.guifont = "FiraCode Nerd Font:h12"
            '';

            statusline.lualine.enable = true; # Status line - https://github.com/nvim-lualine/lualine.nvim
            visuals.nvim-web-devicons.enable = true; # File and status icons - https://github.com/nvim-tree/nvim-web-devicons
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
                  types = [
                    "statix"
                    "deadnix"
                  ];
                };
              };
              typescript.enable = true;
              rust.enable = true;
            };
          };
        };
      };
    };

    homeManager = {pkgs, ...}: {
      programs.vscode = {
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

      programs.zed-editor = {
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
}
