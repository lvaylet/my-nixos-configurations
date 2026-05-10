# Module outputting a standalone home-manager configuration and a module for it. Module is also reused above in the configuration.
{
  self,
  inputs,
  ...
}: {
  # This is your standalone home-manager configuration, meant to be used on non-nixos machines
  # with the `home-manager` command.
  flake.homeConfigurations.laurent = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
    modules = [
      self.homeModules.laurent
      {
        home.username = "laurent";
        home.homeDirectory = "/home/laurent";
      }
    ];
  };

  # This is your `home.nix`, your module where you configure Home Manager.
  # It's imported both in standalone configuration above, and in your nixos configuration.
  flake.homeModules.laurent = {pkgs, ...}: {
    imports = [
      self.homeModules.bat
      self.homeModules.direnv
      self.homeModules.eza
      self.homeModules.fd
      self.homeModules.fzf
      self.homeModules.gemini-cli
      self.homeModules.git
      self.homeModules.jq
      self.homeModules.lazygit
      self.homeModules.nnn
      self.homeModules.pyenv
      self.homeModules.ripgrep
      self.homeModules.ssh
      self.homeModules.starship
      self.homeModules.vscode
      self.homeModules.yazi
      self.homeModules.zed-editor
      self.homeModules.zsh
    ];

    home = {
      packages = with pkgs; [
        # Fonts
        # ---
        # Nerd Fonts - https://www.nerdfonts.com/
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg

        # Development
        # ---
        antigravity # Experience liftoff with the next-gen agent platform - https://antigravity.google/

        # Internet
        # ---
        google-chrome # Freeware web browser developed by Google - https://www.google.com/chrome/

        # Productivity
        # ---
        obsidian # Powerful knowledge base that works on top of a local folder of plain text Markdown files - https://obsidian.md/

        # Virtualization
        # ---
        vmware-workstation # Industry standard desktop hypervisor for x86-64 architecture - https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion

        # Nix
        # ---
        alejandra # An uncompromising Nix Code Formatter - https://github.com/kamadorueda/alejandra
        deadnix # Scan .nix files for dead code (unused variable bindings) - https://github.com/astro/deadnix
        nixd # A Nix Language Server, based on Nix libraries - https://github.com/nix-community/nixd
        nil # A Nix Language Server, an incremental analysis assistant for writing in Nix - https://github.com/oxalica/nil
        statix # Lints and suggestions for the Nix programming language - https://github.com/oppiliappan/statix
        nh # Yet another Nix CLI helper - https://github.com/nix-community/nh
        cachix # A service for Nix binary cache hosting - https://github.com/cachix/cachix
      ];

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

    # Allow fontconfig to discover fonts and configurations installed through `home.packages` and `nix-env`.
    # Source: https://mynixos.com/home-manager/option/fonts.fontconfig.enable
    fonts.fontconfig.enable = true;
  };
}
