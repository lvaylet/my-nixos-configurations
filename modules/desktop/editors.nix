{
  flake.modules.desktop.editors = {
    homeManager = {
      lib,
      outputs,
      pkgs,
      ...
    }: {
      home.packages =
        # Wayland clipboard integration for Niri and Neovim on Linux
        lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.wl-clipboard
        ];

      programs = {
        vscode = {
          enable = true;
          profiles.default = {
            extensions = outputs.lib.vscode.extensions pkgs;
            userSettings = outputs.lib.vscode.settings;
          };
        };

        zed-editor = {
          enable = true;

          # This populates auto_install_extensions` in User Settings.
          extensions = [
            # Themes and Icon Themes
            # ---
            "nord"
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
              mode = "dark";
              light = "One Light";
              dark = "Nord";
            };
            iconTheme = "Material Icon Theme";

            buffer_font_family = "FiraCode Nerd Font";
            buffer_font_size = 12;
            buffer_font_features = {
              calt = true;
            };

            terminal = {
              font_family = "FiraCode Nerd Font";
              font_size = 12;
            };

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
