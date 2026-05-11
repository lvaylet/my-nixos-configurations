{
  description = "My NixOS Configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic Pattern
    # ---
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    # wrapper-modules.url = "github:Birdeehub/nix-wrapper-modules";

    # Manage Neovim with `nvf`.
    # References:
    # - https://www.youtube.com/watch?v=uP9jDrRvAwM
    # - https://nvf.notashelf.dev/#sec-nixos-flakes-usage
    # - https://www.youtube.com/watch?v=VTIGSxpzlIM
    nvf = {
      url = "github:NotAShelf/nvf";
      # You can override the input nixpkgs to follow your system's
      # instance of nixpkgs. This is safe to do as nvf does not depend
      # on a binary cache.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manage Neovim with `nixvim`.
    # Reference: https://nix-community.github.io/nixvim/
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Seamless integration of Git hooks with Nix.
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {inherit inputs;}
    (inputs.import-tree ./modules);
}
