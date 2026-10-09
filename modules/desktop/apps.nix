{
  flake.modules.desktop.apps = {
    nixos = {
      # Enable touchpad support (enabled default in most desktopManager).
      services.libinput.enable = true;
    };

    homeManager = {pkgs, ...}: {
      programs = {
        ghostty = {
          enable = true;
          enableZshIntegration = true;
        };

        # Reference: https://mynixos.com/home-manager/options/programs.obsidian
        obsidian.enable = true;
        # TODO Create `my-obsidian-vault` and check it out from GitHub.

        direnv = {
          enable = true;
          enableZshIntegration = true;
          nix-direnv.enable = true; # Enable a faster, persistent implementation of `use_nix` and `use_flake`, to replace the built-in one.
        };

        eza = {
          enable = true;
          enableZshIntegration = true;
        };

        bat.enable = true;
        fd.enable = true;

        fzf = {
          enable = true;
          enableZshIntegration = true;
        };

        jq.enable = true;
        ripgrep.enable = true;

        yazi = {
          enable = true;
          enableZshIntegration = true;
          package = pkgs.yazi;
        };

        nnn.enable = true;
        opencode.enable = true;

        pyenv = {
          enable = true;
          enableZshIntegration = true;
        };
      };
    };
  };
}
