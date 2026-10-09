{
  flake.modules.desktop.terminal = {
    homeManager = _: {
      # WezTerm GPU-accelerated terminal emulator configuration.
      # Reference: https://wezfurlong.org/wezterm/
      # ---
      programs.wezterm = {
        enable = true;
        enableBashIntegration = false;
        enableZshIntegration = false;
        extraConfig = ''
          local config = wezterm.config_builder()

          -- Typography and ligatures (FiraCode Nerd Font)
          config.font = wezterm.font('FiraCode Nerd Font')
          config.font_size = 11.5
          config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

          -- Visual theme matching Neovim
          config.color_scheme = 'Catppuccin Mocha'

          -- Default interactive shell
          config.default_prog = { 'fish' }

          -- Wayland and ergonomics
          config.enable_wayland = true
          config.window_close_confirmation = 'NeverPrompt'
          config.window_padding = {
            left = 8,
            right = 8,
            top = 8,
            bottom = 8,
          }

          return config
        '';
      };
    };
  };
}
