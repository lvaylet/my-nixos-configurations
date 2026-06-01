{osConfig, ...}: {
  imports = [
    ./_packages.nix

    ./fonts.nix

    # Shell
    ./_zsh.nix
  ];

  home = {
    username = osConfig.vars.userName;
    homeDirectory = "/home/${osConfig.vars.userName}";

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';

      # The configuration files below are not compatible with Yazi 0.3.3 (Nixpkgs 2024-09-04) installed by Home Manager. Use flakes instead to access the latest, bleeding edge version?
      # ".config/yazi/yazi.toml".source = dotfiles/yazi/yazi.toml;
      # ".config/yazi/keymap.toml".source = dotfiles/yazi/keymap.toml;
      # ".config/yazi/theme.toml".source = dotfiles/yazi/theme.toml;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "26.05";
  };

  # Whether new or changed services that are wanted by active targets should be started.
  # Additionally, stop obsolete services from the previous generation.
  # The alternatives are
  # - `suggest` (or `false`) : Use a very simple shell script to print suggested `systemctl`
  #   commands to run. You will have to manually run those commands after the switch.
  # - `sd-switch` (or `true`) : Use `sd-switch`, a tool that determines the necessary changes and
  #   automatically apply them.
  systemd.user.startServices = "sd-switch";
}
