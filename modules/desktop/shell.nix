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
          enableZshIntegration = true;
        };

        zsh = {
          enable = true;
          autocd = true;
          defaultKeymap = "viins";
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

            # Utils
            b = "btop";
            d = "ncdu --exclude /mnt --color dark "; # + path
          };
        };
      };

      home.file.".config/starship.toml".source = ./dotfiles/starship.toml;
    };
  };
}
