# Interface Contract: LazyVim Desktop Module

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](../spec.md)

This contract defines the schema, module export signatures, and behavioral guarantees for the desktop editors module in `modules/desktop/editors.nix`.

---

## 1. Nix Module Interface

`modules/desktop/editors.nix` MUST export a dendritic Home Manager module under `flake.modules.desktop.editors.homeManager`.

```nix
{
  flake.modules.desktop.editors = {
    homeManager = {pkgs, ...}: {
      # Neovim application configuration
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withNodeJs = true;
        withPython3 = true;
      };

      # Upstream LazyVim runtime dependencies
      home.packages = with pkgs; [
        git
        gcc
        gnumake
        ripgrep
        fd
        curl
        unzip
        tar
        gzip
        wl-clipboard
      ];

      # Declarative LazyVim starter configuration symlink
      xdg.configFile."nvim".source = ./dotfiles/nvim;

      # Existing VS Code and Zed editor configurations remain untouched
      # ...
    };
  };
}
```

---

## 2. Behavioral Guarantees

1. **Discovery & Export**:
   - The file `modules/desktop/editors.nix` is discovered automatically by `import-tree ./modules`.
   - The module definition is registered into `config.flake.modules.desktop.editors`.
2. **Deprecation of `nvf`**:
   - The `nixos` block importing `inputs.nvf.nixosModules.default` and defining `programs.nvf` is removed from `modules/desktop/editors.nix`.
   - NixOS system evaluation no longer evaluates or builds `nvf` packages.
3. **Colocation with Other Editors**:
   - The existing configurations for `programs.vscode` and `programs.zed-editor` remain fully functional and co-located within `homeManager` in `modules/desktop/editors.nix`.
4. **Environment Aliases**:
   - `vi` and `vim` executable names in the user's shell resolve directly to the configured `neovim` package.
   - `$EDITOR` and `$VISUAL` environment variables are populated with `nvim`.
