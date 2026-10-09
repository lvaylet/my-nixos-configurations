# Interface Contract: Host Composition

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](../spec.md)

This contract defines the format for declaring machine targets in `modules/hosts/`.

---

## 1. Host Module Structure

Each target machine file under `modules/hosts/<hostname>.nix` is a top-level `flake-parts` module:

```nix
{ config, inputs, ... }:
let
  inherit (config.flake.lib) mkHost;
in
{
  flake.nixosConfigurations.<hostname> = mkHost {
    system = "x86_64-linux"; # Target architecture
    hardware = ./hardware/<hostname>.nix; # Machine hardware spec
    features = [
      # List of enabled feature keys registered in flake.modules
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
    extraModules = [
      # Optional host-unique modules (e.g., installer CD minimal module)
    ];
  };
}
```

---

## 2. `mkHost` Builder Contract

The `mkHost` helper defined in `modules/core/lib.nix` provides the following behavior:

1. **System Instantiation**: Invokes `inputs.nixpkgs.lib.nixosSystem` for the specified `system`.
2. **Special Arguments**: Passes `inputs`, `outputs = config.flake`, and `vars = config.flake.vars` into `specialArgs` and `extraSpecialArgs`.
3. **Module Resolution**:
   - Collects the `nixos` submodules from all specified `features` in `config.flake.modules`.
   - Injects the hardware module at `hardware`.
   - Injects any modules specified in `extraModules`.
4. **Embedded Home Manager**:
   - Imports `inputs.home-manager.nixosModules.home-manager`.
   - Collects the `homeManager` submodules from all specified `features`.
   - Sets `home-manager.users.${config.flake.vars.user}.imports` to include those submodules.
   - Binds `home.stateVersion = osConfig.system.stateVersion`.
   - Enables `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`.
