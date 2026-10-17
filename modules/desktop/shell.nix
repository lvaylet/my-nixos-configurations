{
  flake.modules.desktop.shell = {
    homeManager = _: {
      # Fish interactive shell configuration.
      # Reference: https://fishshell.com/
      # ---
      programs = {
        fish = {
          enable = true;
          interactiveShellInit = ''
            set -g fish_greeting ""

            # Nord color palette for Fish syntax highlighting and completion pager
            set -g fish_color_normal d8dee9
            set -g fish_color_command 81a1c1
            set -g fish_color_keyword 81a1c1
            set -g fish_color_quote a3be8c
            set -g fish_color_redirection b48ead
            set -g fish_color_end 88c0d0
            set -g fish_color_error bf616a
            set -g fish_color_param d8dee9
            set -g fish_color_comment 4c566a
            set -g fish_color_selection --background=434c5e
            set -g fish_color_search_match --bold --background=434c5e
            set -g fish_color_operator 81a1c1
            set -g fish_color_escape ebcb8b
            set -g fish_color_autosuggestion 4c566a
            set -g fish_pager_color_progress d8dee9 --background=434c5e
            set -g fish_pager_color_prefix 88c0d0 --bold --underline
            set -g fish_pager_color_completion d8dee9
            set -g fish_pager_color_description ebcb8b
            set -g fish_pager_color_selected_background --background=434c5e
          '';
          shellAliases = {
            c = "clear";
            x = "exit";
            r = "source ~/.config/fish/config.fish";
            cat = "bat";
            y = "yazi";

            # `ls` / `eza`
            ls = "eza --group --group-directories-first --icons --header --time-style long-iso";
            ll = "eza --group --group-directories-first --icons --header --time-style long-iso --long";
            llt = "eza --group --group-directories-first --icons --header --time-style long-iso --long --tree";
            la = "eza --group --group-directories-first --icons --header --time-style long-iso --long --all";
            lat = "eza --group --group-directories-first --icons --header --time-style long-iso --long --all --tree";

            # Utils
            b = "btop";
            d = "ncdu --exclude /mnt --color dark ";
          };
          functions = {
            take = ''
              mkdir -p $argv[1]
              and cd $argv[1]
            '';
          };
        };

        # Enable Starship prompt integration.
        # ---
        starship = {
          enable = true;
          enableFishIntegration = true;
        };
      };

      home.file.".config/starship.toml".source = ./dotfiles/starship.toml;
    };
  };
}
