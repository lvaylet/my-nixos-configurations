_: {
  flake.nixosModules.neovim = _: {
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

          statusline.lualine.enable = true; # Status line - https://github.com/nvim-lualine/lualine.nvim
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
                types = ["statix" "deadnix"];
              };
            };
            typescript.enable = true;
            rust.enable = true;
          };
        };
      };
    };
  };
}
