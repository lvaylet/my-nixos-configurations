{pkgs, ...}: {
  programs.vscode = {
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

        "workbench.colorTheme" = "Catppuccin Macchiato"; # or "One Dark Pro"
        "workbench.iconTheme" = "catppuccin-macchiato"; # or "material-icon-theme"

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
}
