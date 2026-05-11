{inputs, ...}: {
  flake.nixosModules.lazyvim = {
    imports = [
      inputs.nixvim.nixosModules.nixvim
    ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      viAlias = true;
      vimAlias = true;

      # Global variables for LazyVim
      globals = {
        mapleader = " ";
        maplocalleader = "\\";
        autoformat = true; # Enable autoformat by default
        snacks_animate = true;
        lazyvim_picker = "auto"; # telescope, fzf, or auto
        lazyvim_cmp = "auto"; # nvim-cmp, blink.cmp, or auto
      };

      plugins = {
        # Reproduce LazyVim base configuration
        # References:
        # - https://nix-community.github.io/nixvim/plugins/lazyvim/index.html
        # - https://www.lazyvim.org/
        lazyvim = {
          enable = true;
          # Reproduce default starter pack settings.
          extras = [
            "coding.luasnip"
            "formatting.conform"
            "lang.json"
            "ui.edgy"
          ];
        };

        # Snacks.nvim - Core part of modern LazyVim
        snacks = {
          enable = true;
          settings = {
            bigfile.enabled = true;
            dashboard.enabled = true;
            indent.enabled = true;
            input.enabled = true;
            notifier.enabled = true;
            quickfile.enabled = true;
            scroll.enabled = true;
            statuscolumn.enabled = true;
            words.enabled = true;
          };
        };

        # Configure icons. Requires Nerd Font.
        web-devicons.enable = true;

        # Disable Mason to avoid issues with dynamic binaries on NixOS
        mason = {
          enable = false;
        };

        # Base plugins that LazyVim expects/uses, managed via NixVim
        treesitter = {
          enable = true;
          nixGrammars = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };

        # These plugins are typically part of LazyVim core
        # We enable them here to ensure they are available through Nix
        telescope.enable = true;
        lualine.enable = true;
        neo-tree.enable = true;
        which-key.enable = true;
        bufferline.enable = true;
        noice.enable = true;
        notify.enable = true;
        todo-comments.enable = true;
        gitsigns.enable = true;
        trouble.enable = true;
        indent-blankline.enable = true;

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings.sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
            {name = "luasnip";}
          ];
        };

        # LSP Configuration (managed via Nix)
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
          };
        };

        # Formatting (managed via Nix)
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              nix = ["alejandra"];
            };
            format_on_save = {
              lsp_fallback = true;
              timeout_ms = 500;
            };
          };
        };
      };

      # Colorscheme: LazyVim defaults to tokyonight
      colorschemes.tokyonight = {
        enable = true;
        settings.style = "moon";
      };

      # Reproduce `options.lua` from LazyVim core.
      opts = {
        autowrite = true; # Enable auto write
        clipboard = "unnamedplus"; # Sync with system clipboard
        completeopt = "menu,menuone,noselect";
        conceallevel = 2; # Hide * markup for bold and italic
        confirm = true; # Confirm to save changes before exiting
        cursorline = true; # Enable highlighting of the current line
        expandtab = true; # Use spaces instead of tabs
        formatoptions = "jcroqlnt"; # tcqj
        grepformat = "%f:%l:%c:%m";
        grepprg = "rg --vimgrep";
        ignorecase = true; # Ignore case
        inccommand = "nosplit"; # preview incremental substitute
        laststatus = 3; # global statusline
        list = true; # Show some invisible characters
        mouse = "a"; # Enable mouse mode
        number = true; # Print line number
        pumblend = 10; # Popup blend
        pumheight = 10; # Maximum number of entries in a popup
        relativenumber = true; # Relative line numbers
        scrolloff = 4; # Lines of context
        sessionoptions = ["buffers" "curdir" "tabpages" "winsize" "help" "globals" "skiprtp" "folds"];
        shiftround = true; # Round indent
        shiftwidth = 2; # Size of an indent
        shortmess = "WICc"; # See :h shortmess
        showmode = false; # Dont show mode since we have a statusline
        sidescrolloff = 8; # Columns of context
        signcolumn = "yes"; # Always show the signcolumn
        smartcase = true; # Don't ignore case with capitals
        smartindent = true; # Insert indents automatically
        spelllang = ["en"];
        splitbelow = true; # Put new windows below current
        splitkeep = "screen";
        splitright = true; # Put new windows right of current
        tabstop = 2; # Number of spaces tabs count for
        termguicolors = true; # True color support
        timeoutlen = 300;
        undofile = true;
        undolevels = 10000;
        updatetime = 200; # Save swap file and trigger CursorHold
        virtualedit = "block"; # Allow cursor to move where there is no text in visual block mode
        wildmode = "longest:full,full"; # Command-line completion mode
        winminwidth = 5; # Minimum window width
        wrap = false; # Disable line wrap
      };

      # Keymaps: LazyVim defines many, we add the explorer one as requested
      keymaps = [
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>Neotree toggle<CR>";
          options.desc = "Explorer NeoTree (Root Dir)";
        }
      ];
    };
  };
}
