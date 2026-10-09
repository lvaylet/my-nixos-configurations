# Data Model: Dendritic Pattern Migration

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration attributes, data relationships, and validation rules governing the dendritic architecture.

---

## 1. Entities & Structural Hierarchy

### 1.1 Flake Root Engine (`flake.nix`)
The top-level flake orchestration layer.
- **Attributes**:
  - `inputs`: Attribute set of pinned upstream flake references (`nixpkgs`, `home-manager`, `nvf`, `noctalia`, `git-hooks`, `flake-parts`, `import-tree`).
  - `outputs`: Function taking `inputs` and invoking `flake-parts.lib.mkFlake` with `(import-tree ./modules)`.
- **Relationships**:
  - Discovers all `ModuleFile` entities under `modules/` via `import-tree`.
  - Aggregates and produces top-level `FlakeOutput` entities (`nixosConfigurations`, `devShells`, `checks`, `formatter`).

### 1.2 Module File (`modules/**/*.nix`)
Every non-entrypoint file in `modules/` is a top-level `flake-parts` module.
- **Attributes**:
  - `path`: Filesystem path within `modules/` relative to repo root.
  - `domain`: Functional area determined by parent folder (`core`, `desktop`, `services`, `hosts`).
  - `definition`: Nix function receiving `{ config, lib, inputs, pkgs, ... }`.
- **Validation Rules**:
  - MUST format cleanly with `alejandra`.
  - MUST pass `deadnix` and `statix check` with zero warnings.
  - MUST NOT use imperative file imports; references between modules rely on `config` or `inputs`.

### 1.3 Feature (Aspect)
A cohesive, named capability providing system services, user packages, configurations, and static dotfiles.
- **Attributes**:
  - `name`: Unique identifier for the capability (e.g., `base`, `desktop-session`, `terminal`, `shell`, `audio`, `tailscale`, `podman`).
  - `nixos`: Deferred NixOS module configuring system daemons, hardware drivers, firewall rules, or kernel parameters (optional).
  - `homeManager`: Deferred Home Manager module configuring user packages, shell environments, dotfiles, or desktop applications (optional).
- **Validation Rules**:
  - MUST define at least one of `nixos` or `homeManager`.
  - MUST be self-contained: enabling the feature brings all necessary configuration for that capability.

### 1.4 Target (Machine / Host)
A deployable system closure representing a concrete machine or installation image.
- **Attributes**:
  - `hostname`: Unique machine identifier (`desktop-pc`, `homelab`, `iso`).
  - `system`: Target architecture triple (default `x86_64-linux`).
  - `hardware`: Path to the hardware specification module (e.g., `./hardware/desktop-pc.nix`).
  - `features`: List of enabled `Feature` names.
  - `extraModules`: Optional host-unique NixOS modules (e.g., installer CD minimal module for `iso`).
- **Relationships**:
  - Composes multiple `Feature` entities into a unified `nixosSystem` closure.
  - Associates `homeManager` components of all enabled features with the primary `User` entity.

### 1.5 Shared Identity Context (`flake.vars`)
Global repository-wide identity and parameter options defined in `modules/core/vars.nix`.
- **Attributes**:
  - `user`: Primary user login name (string, default `"laurent"`).
  - `fullName`: User display name (string, default `"Laurent Vaylet"`).
  - `email`: Primary email address (string, default `"laurent.vaylet@gmail.com"`).
  - `sshPublicKey`: Authorized public SSH key (string).
- **Validation Rules**:
  - All attributes MUST be non-empty strings.
  - Secrets and private keys MUST NOT be declared here (strictly public identity metadata).

---

## 2. Entity Relationship Diagram

```text
+-----------------------------------------------------------+
|                        flake.nix                          |
|         (mkFlake + import-tree ./modules)                 |
+-----------------------------------------------------------+
                              |
              discovers and imports all files
                              v
+-----------------------------------------------------------+
|                   modules/ Tree                           |
+-----------------------------------------------------------+
  |              |                      |                 |
  v              v                      v                 v
modules/core/  modules/desktop/       modules/services/  modules/hosts/
  |              |                      |                 |
  |              +----------+-----------+                 |
  |                         |                             |
  |                         v                             v
  |               +-------------------+         +-------------------+
  |               |  Feature Entities |         |  Target Entities  |
  |               |  (name, nixos,    |         |  (hostname,       |
  |               |   homeManager)    |         |   hardware,       |
  |               +-------------------+         |   features[])     |
  |                         |                   +-------------------+
  |                         |                             |
  |                         +--------------+--------------+
  |                                        |
  v                                        v
+------------------+             +-------------------+
|  config.vars     |             |  mkHost Builder   |
|  (identity ctx)  |             |  (assembles host  |
+------------------+             |   + embedded HM)  |
                                 +-------------------+
                                           |
                                           v
                             +---------------------------+
                             |   Flake Output Closures   |
                             |   .#desktop-pc            |
                             |   .#homelab               |
                             |   .#iso                   |
                             +---------------------------+
```

---

## 3. Host Feature Mapping Matrix

| Host Target | Architecture | Hardware Spec | Enabled Feature Capabilities |
|---|---|---|---|
| **`desktop-pc`** | `x86_64-linux` | `hardware/desktop-pc.nix` | `base`, `desktop-session`, `terminal`, `shell`, `fonts`, `editors`, `audio`, `graphics`, `network`, `ssh`, `tailscale`, `podman`, `printing`, `ssd`, `apps`, `virtualization` |
| **`homelab`** | `x86_64-linux` | `hardware/homelab.nix` | `base`, `shell`, `editors`, `network`, `ssh`, `tailscale`, `podman`, `media`, `jellyfin`, `qbittorrent`, `filebrowser`, `adguardhome`, `home-automation` |
| **`iso`** | `x86_64-linux` | Minimal CD ISO base | `base`, `shell`, `editors`, `network`, `ssh` |

---

## 4. Lifecycle & Evaluation States

1. **Flake Evaluation**:
   - Nix evaluates `flake.nix`.
   - `import-tree` recursively crawls `modules/`, collecting all `.nix` file paths (ignoring paths with leading `_` or in excluded directories).
   - `flake-parts` evaluates all module files as a unified top-level configuration.
2. **Feature Registration**:
   - Each module file in `core/`, `desktop/`, and `services/` registers its capabilities under `config.flake.modules`.
   - `modules/core/vars.nix` registers `config.flake.vars`.
3. **Host Assembly**:
   - Each host file in `modules/hosts/` resolves its list of feature names against `config.flake.modules`.
   - `mkHost` constructs a `nixosSystem` combining hardware, system modules, and embedded Home Manager user modules.
   - The resulting system derivations are bound to `config.flake.nixosConfigurations.<hostname>`.
4. **CI & Verification**:
   - `perSystem` outputs expose `checks`, `formatter`, and `devShells` for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.
   - `nix flake check` executes hermetic checks against all targets.
