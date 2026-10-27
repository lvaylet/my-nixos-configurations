{
  description = "My NixOS Configurations (Dendritic Pattern)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system management
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Wayland desktop shell.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative state preservation for impermanence
    preservation = {
      url = "github:nix-community/preservation";
    };

    # Seamless integration of Git hooks with Nix.
    git-hooks.url = "github:cachix/git-hooks.nix";

    # OpenCode AI coding agent (v2)
    opencode = {
      url = "github:anomalyco/opencode/v2.1.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative AI agent skills
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    addyosmani-agent-skills = {
      url = "github:addyosmani/agent-skills";
      flake = false;
    };

    # Dendritic pattern framework & tree discovery
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./modules);
}
