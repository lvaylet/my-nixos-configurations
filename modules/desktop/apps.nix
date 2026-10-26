{
  flake.modules.desktop.apps = {
    nixos = {
      # Enable touchpad support (enabled default in most desktopManager).
      services.libinput.enable = true;
    };

    homeManager = {
      lib,
      pkgs,
      ...
    }: {
      home.packages = with pkgs;
        [
          google-chrome # A freeware web browser developed by Google - https://www.google.com/chrome/
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          # GUI & Partitioning Tools (Linux only)
          # ---
          efibootmgr
          gptfdisk
          parted
          tparted
        ];

      programs = {
        ghostty = {
          enable = true;
          package =
            if pkgs.stdenv.hostPlatform.isDarwin
            then null
            else pkgs.ghostty;
          settings = {
            theme = "Nord";
            font-family = "FiraCode Nerd Font";
            font-feature = [
              "calt"
              "clig"
              "liga"
            ];
          };
        };

        # Reference: https://mynixos.com/home-manager/options/programs.obsidian
        obsidian.enable = true;
        # TODO Create `my-obsidian-vault` and check it out from GitHub.

        eza = {
          enable = true;
          enableFishIntegration = true;
        };

        bat = {
          enable = true;
          config = {
            theme = "Nord";
          };
        };

        btop = {
          enable = true;
          settings = {
            color_theme = "nord";
          };
        };

        fd.enable = true;

        fzf = {
          enable = true;
          enableFishIntegration = true;
          colors = {
            bg = "#2e3440";
            "bg+" = "#3b4252";
            fg = "#d8dee9";
            "fg+" = "#eceff4";
            hl = "#88c0d0";
            "hl+" = "#8fbcbb";
            info = "#ebcb8b";
            prompt = "#81a1c1";
            pointer = "#88c0d0";
            marker = "#a3be8c";
            spinner = "#b48ead";
            header = "#5e81ac";
            border = "#4c566a";
          };
        };

        jq.enable = true;
        ripgrep.enable = true;

        yazi = {
          enable = true;
          enableFishIntegration = true;
          package = pkgs.yazi;
          theme = {
            mgr = {
              cwd = {
                fg = "#88c0d0";
              };
              hovered = {
                reversed = true;
              };
              preview_hovered = {
                underline = true;
              };
              find_keyword = {
                fg = "#ebcb8b";
                bold = true;
                italic = true;
                underline = true;
              };
              find_position = {
                fg = "#b48ead";
                bg = "reset";
                bold = true;
                italic = true;
              };
              marker_copied = {
                fg = "#a3be8c";
                bg = "#a3be8c";
              };
              marker_cut = {
                fg = "#bf616a";
                bg = "#bf616a";
              };
              marker_marked = {
                fg = "#88c0d0";
                bg = "#88c0d0";
              };
              marker_selected = {
                fg = "#ebcb8b";
                bg = "#ebcb8b";
              };
              tab_active = {
                reversed = true;
              };
              tab_inactive = {};
              tab_width = 1;
              count_copied = {
                fg = "#2e3440";
                bg = "#a3be8c";
              };
              count_cut = {
                fg = "#2e3440";
                bg = "#bf616a";
              };
              count_selected = {
                fg = "#2e3440";
                bg = "#ebcb8b";
              };
              border_symbol = "│";
              border_style = {
                fg = "#4c566a";
              };
            };
            status = {
              overall = {};
              sep_left = {
                open = "";
                close = "";
              };
              sep_right = {
                open = "";
                close = "";
              };
              perm_sep = {
                fg = "#4c566a";
              };
              perm_type = {
                fg = "#81a1c1";
              };
              perm_read = {
                fg = "#ebcb8b";
              };
              perm_write = {
                fg = "#bf616a";
              };
              perm_exec = {
                fg = "#a3be8c";
              };
              progress_label = {
                fg = "#eceff4";
                bold = true;
              };
              progress_normal = {
                fg = "#81a1c1";
                bg = "#3b4252";
              };
              progress_error = {
                fg = "#bf616a";
                bg = "#3b4252";
              };
            };
          };
        };

        nnn.enable = true;

        pyenv.enable = true;
      };
    };
  };
}
