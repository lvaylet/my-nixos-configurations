# Technical Research: Codebase Migration to the Dendritic Pattern

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives considered for migrating the NixOS flake codebase to the Dendritic Pattern.

---

## 1. Orchestration Engine & Module Auto-Discovery

### Decision
Adopt **`flake-parts`** (`github:hercules-ci/flake-parts`) as the top-level module system framework paired with **`import-tree`** (`github:denful/import-tree`) to automatically discover and evaluate all modules within `modules/`.

```nix
# flake.nix
{
  description = "My NixOS Configurations (Dendritic Pattern)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

### Rationale
- **Community Reference Standard**: `flake-parts` combined with `import-tree` is the established, battle-tested standard for the Dendritic Pattern in the Nix ecosystem (pioneered by Shahar "Dawn" Or, Pol Dellaiera, and Victor Borja).
- **Minimal Root Flake**: `flake.nix` becomes a declarative, 30-line entrypoint that never needs modification when adding new features or machine configurations.
- **Unified Class Evaluation**: Every non-entrypoint file in `modules/` is evaluated as a top-level `flake-parts` module, giving it direct access to `inputs`, `self`, `config`, and `pkgs`.
- **Built-in Multi-System Support**: `flake-parts` natively provides `perSystem` outputs (`checks`, `formatter`, `devShells`), eliminating manual `forAllSystems` helper boilerplate.

### Alternatives Considered
- **`vic/den` Framework**: Explored by the community for aspect-oriented programming. While conceptually powerful, Den introduces a higher learning curve, custom schema layers (`den.schema`, `den.aspects`), and mutual-provider routing complexity between hosts and users. Rejected in favor of the cleaner, standard `flake-parts` approach.
- **Pure `lib.evalModules` without `flake-parts`**: Feasible but requires re-implementing multi-system dispatch, output schemas, and CLI compatibility from scratch. Rejected due to unnecessary maintenance overhead.

---

## 2. Directory Hierarchy & Domain Grouping

### Decision
Organize the entire codebase under a unified `modules/` tree, segmented into clear functional domains:

```text
modules/
├── core/                  # Flake-level settings, systems, vars, devshell, checks, formatter, base OS
│   ├── systems.nix        # Multi-system configuration
│   ├── vars.nix           # Global identity & user parameters as flake options
│   ├── base.nix           # Foundation NixOS system configuration (locales, nix settings, etc.)
│   ├── devshell.nix       # Development shell with just, nh, and pre-commit hooks
│   ├── checks.nix         # Pre-commit checks sandbox via git-hooks.nix
│   └── formatter.nix      # Pre-commit run formatter for nix fmt
├── desktop/               # Graphical environment, compositor, terminal, fonts, GUI tools
│   ├── session.nix        # Niri compositor + Noctalia desktop shell + Greetd greeter
│   ├── terminal.nix       # WezTerm terminal emulator configuration
│   ├── shell.nix          # Fish interactive shell & Starship prompt
│   ├── fonts.nix          # System and user fonts (FiraCode Nerd Font)
│   ├── editors.nix        # Neovim (nvf), VS Code, Zed editor
│   ├── audio.nix          # Pipewire sound configuration
│   ├── graphics.nix       # Nvidia GPU acceleration & prime settings
│   └── apps.nix           # Desktop user applications (Ghostty, Obsidian, etc.)
├── services/              # Headless services, server daemons, networking, virtualization
│   ├── network.nix        # NetworkManager, firewall, base connectivity
│   ├── ssh.nix            # OpenSSH daemon and user SSH keys
│   ├── tailscale.nix      # Tailscale mesh VPN
│   ├── podman.nix         # Podman container runtime
│   ├── media.nix          # Media directory layout & permissions
│   ├── jellyfin.nix       # Jellyfin media server daemon
│   ├── qbittorrent.nix    # Headless torrent service
│   ├── filebrowser.nix    # Web file management daemon
│   ├── adguardhome.nix    # DNS filtering service
│   ├── home-automation.nix# Home automation daemons
│   ├── printing.nix       # CUPS printing service
│   ├── ssd.nix            # Periodic fstrim service
│   └── virtualization.nix # VMware Workstation & hypervisor tools
└── hosts/                 # Concrete target machine declarations & hardware specs
    ├── hardware/          # Machine-unique hardware scans
    │   ├── desktop-pc.nix # Desktop PC hardware configuration
    │   └── homelab.nix    # Homelab hardware configuration (dummy)
    ├── desktop-pc.nix     # Desktop workstation closure definition & feature selection
    ├── homelab.nix        # Homelab server closure definition & feature selection
    └── iso.nix            # Bootable installer ISO closure definition & feature selection
```

### Rationale
- **Feature Colocation**: Eliminates the artificial split between `modules/nixos/` and `modules/home-manager/`.
- **Single Traversal Root**: `import-tree ./modules` traverses the entire repository structure seamlessly.
- **Domain Cohesion**: Files are organized by their practical business capability (desktop, services, core, hosts).

### Alternatives Considered
- **Flat `modules/*.nix` layout**: Over 40 files in a single flat directory creates navigation clutter. Domain grouping is significantly cleaner.
- **Separate `features/` and `hosts/` roots**: Requires multiple `import-tree` invocations in `flake.nix`. A single `modules/` root is more idiomatic.

---

## 3. Feature Modeling & Host Composition Pattern

### Decision
Model features as modular building blocks aggregated under `flake.modules.nixos` and `flake.modules.homeManager` (or combined host-composition helpers):

```nix
# Example: modules/desktop/terminal.nix
{
  flake.modules.desktop.terminal = {
    # System-level configurations (if any)
    nixos = { ... };

    # User-level configurations
    homeManager = {
      programs.wezterm = {
        enable = true;
        # ...
      };
    };
  };
}
```

To streamline host assembly, provide a composition helper in `modules/core/lib.nix` that takes a list of enabled feature names and resolves their system and user modules:

```nix
# modules/hosts/desktop-pc.nix
{ config, inputs, ... }:
let
  inherit (config.flake.lib) mkHost;
in
{
  flake.nixosConfigurations.desktop-pc = mkHost {
    system = "x86_64-linux";
    hardware = ./hardware/desktop-pc.nix;
    features = [
      "base"
      "desktop-session"
      "terminal"
      "shell"
      "fonts"
      "editors"
      "audio"
      "graphics"
      "network"
      "ssh"
      "tailscale"
      "podman"
    ];
  };
}
```

### Rationale
- **Inversion of Control**: Host definitions simply declare their role by enumerating feature names.
- **Automatic Home Manager Embedding**: The `mkHost` helper automatically injects `home-manager.nixosModules.home-manager` and maps user modules into `home-manager.users.${config.flake.vars.user}`.
- **Zero Duplication**: Feature logic is defined exactly once.

---

## 4. Shared Variables & Identity Management

### Decision
Centralize repository identity and configuration options in `modules/core/vars.nix` as a `flake-parts` module option:

```nix
# modules/core/vars.nix
{ lib, ... }:
{
  options.flake.vars = lib.mkOption {
    type = lib.types.submodule {
      options = {
        user = lib.mkOption { type = lib.types.str; default = "laurent"; };
        fullName = lib.mkOption { type = lib.types.str; default = "Laurent Vaylet"; };
        email = lib.mkOption { type = lib.types.str; default = "laurent.vaylet@gmail.com"; };
        sshPublicKey = lib.mkOption {
          type = lib.types.str;
          default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPq0jD6rB1L60O3tW2iZ6Q5qZp1t2o3p4q5r6s7t8u9v";
        };
      };
    };
    default = {};
  };
}
```

All other modules can directly reference `config.flake.vars` without parameter plumbing. For compatibility with lower-level module functions that take `vars` as an argument, `mkHost` passes `vars = config.flake.vars` into `specialArgs` and `extraSpecialArgs`.

### Rationale
- **Type Safety**: Nixpkgs module options enforce types and defaults.
- **Eliminates `vars.nix` File Imports**: Replaces imperative `import ./vars.nix` calls across modules with declarative `config.flake.vars`.

---

## 5. Migration Strategy & Operational Continuity

### Decision
Execute an **atomic conversion**:
1. Add `flake-parts` and `denful/import-tree` to `flake.nix`.
2. Construct the new `modules/` tree (`core/`, `desktop/`, `services/`, `hosts/`).
3. Port all NixOS and Home Manager logic from legacy folders into the new domain modules.
4. Update `flake.nix` to invoke `import-tree ./modules`.
5. Remove legacy `modules/nixos/`, `modules/home-manager/`, `machines/`, and `vars.nix`.
6. Validate with `just check`, `just lint`, `just fmt`, and closure dry-runs.

### Rationale
- Prevents split-brain architectures where two conflicting module systems coexist.
- Guarantees immediate verification of the complete target closure graph.
