_: {
  config.flake.lib.vscode = let
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

      "chat.editor.fontFamily" = "FiraCode Nerd Font";
      "debug.console.fontFamily" = "FiraCode Nerd Font";
      "scm.inputFontFamily" = "FiraCode Nerd Font";

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
  in {
    extensions = pkgs:
      with pkgs.vscode-extensions; [
        # GitHub
        # ---
        github.vscode-github-actions # GitHub Actions
        github.vscode-pull-request-github # GitHub Pull Requests and Issues

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

    inherit userSettings;
    settings = userSettings;
  };
}
