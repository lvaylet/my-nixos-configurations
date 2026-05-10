_: {
  flake.homeModules.zed-editor = _: {
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
}
