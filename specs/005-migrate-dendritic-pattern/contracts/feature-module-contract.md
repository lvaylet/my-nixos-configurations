# Interface Contract: Dendritic Feature Module

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](../spec.md)

This contract defines the format and schema for declaring a dendritic feature module inside `modules/`.

---

## 1. Top-Level Module Definition

Every feature module file is a top-level `flake-parts` module accepting standard arguments:

```nix
{ config, lib, inputs, ... }:
{
  # Feature registration under flake.modules.<domain>.<feature-name>
  flake.modules.<domain>.<feature-name> = {
    # System-level configuration (NixOS)
    nixos = { pkgs, config, lib, ... }: {
      # NixOS services, packages, system options
    };

    # User-level configuration (Home Manager)
    homeManager = { pkgs, config, lib, ... }: {
      # Home Manager packages, dotfiles, user programs
    };
  };
}
```

---

## 2. Rules & Invariants

1. **Self-Sufficiency**: A feature encapsulates all necessary settings for its functionality.
2. **Optional Submodules**:
   - If a feature only provides system configuration (e.g., `graphics.nix`, `ssd.nix`), the `homeManager` attribute MAY be omitted or set to `{}`.
   - If a feature only provides user configuration (e.g., `terminal.nix`, `editors.nix`), the `nixos` attribute MAY be omitted or set to `{}`.
3. **Parameter Access**:
   - Repository-wide parameters (user name, email, keys) are accessed via `config.flake.vars`.
   - Flake inputs are accessed via `inputs.<name>`.
4. **Auto-Discovery**:
   - The file MUST NOT be explicitly imported in `flake.nix`.
   - The file MUST be discovered automatically by `import-tree ./modules`.
   - The filename MUST NOT start with an underscore (`_`), as leading underscores are ignored by `import-tree`.
