# Phase 1 Data Model: Harmonize Task Runner (`justfile`) Recipes and Syntax Across Hosts

**Feature**: `028-harmonize-justfile-recipes`
**Date**: 2026-10-26

## Entities

### 1. Managed Host Configuration (`HostConfiguration`)

Represents a declarative flake system target that can be operated via `justfile` recipes.

| Attribute | Type | Allowed Values | Description |
| --- | --- | --- | --- |
| `name` | `string` | `desktop-pc`, `homelab`, `macbook-air-m4-15`, `iso` | Flake output identifier. |
| `platformFamily` | `enum` | `nixos`, `darwin`, `iso` | Determines which flake output path (`nixosConfigurations` vs `darwinConfigurations`) and activation tool (`nh os` / `nixos-rebuild` vs `nix-darwin`) is used. |
| `architecture` | `string` | `x86_64-linux`, `aarch64-darwin` | Target hardware/OS platform. |
| `supportsRemoteSudo` | `boolean` | `true` (`desktop-pc`, `homelab`), `false` (`macbook-air-m4-15`, `iso`) | Indicates whether remote SSH activation via `--use-remote-sudo` / `nh os --target-host` is supported. |

### 2. Task Runner Recipe (`JustRecipe`)

Represents an executable recipe declared in `justfile`.

| Attribute | Type | Description |
| --- | --- | --- |
| `verb` | `string` | Lifecycle action (`build`, `test`, `switch`, `boot`, `install`, `build-iso`, or utility recipe name). |
| `group` | `string` | `[group('...')]` category (`(re)build`, `dev-utils`, `flake-management`, `garbage-collection`). |
| `parameters` | `list<Parameter>` | Ordered parameter signature with default values (`configuration=""`, `target=""`). |
| `executionMode` | `enum` | `local-darwin`, `local-nixos`, `remote-nixos`, `local-generic`. |

### 3. Target Resolution Context (`TargetResolution`)

Represents the resolved execution parameters derived at runtime when a user invokes a `(re)build` recipe.

| Input State | Resolved `CONFIG` | Resolved `TARGET` | Execution Path |
| --- | --- | --- | --- |
| `configuration=""`, running on macOS (`Darwin`) | `macbook-air-m4-15` | `""` (local) | `local-darwin` |
| `configuration=""`, running on Linux (`hostname == "homelab"`) | `homelab` | `""` (local) | `local-nixos` |
| `configuration=""`, running on Linux (`hostname == "desktop-pc"` or other) | `desktop-pc` | `""` if on `desktop-pc` NixOS, else `"desktop-pc"` (for `test`/`switch`/`boot`) | `local-nixos` or `remote-nixos` |
| `configuration="homelab"`, `target=""`, running on `desktop-pc` | `homelab` | `""` for `build`; `"homelab"` for `test`/`switch`/`boot` | `local-generic` (`build`) or `remote-nixos` (`test`/`switch`/`boot`) |
| `configuration="homelab"`, `target="192.168.1.180"` | `homelab` | `"192.168.1.180"` | `remote-nixos` |
| `configuration="macbook-air-m4-15"`, running on macOS | `macbook-air-m4-15` | `""` (local) | `local-darwin` |

## Validation Rules

1. **Darwin Guard**: `test` and `switch` with `CONFIG == "macbook-air-m4-15"` MUST verify `uname -s == "Darwin"`. `boot` and `install` with `CONFIG == "macbook-air-m4-15"` MUST reject execution with a clear error message.
2. **NixOS Local vs Remote Guard**: When `CONFIG` is a NixOS host (`desktop-pc`, `homelab`) and `TARGET` is empty on `test`, `switch`, or `boot`, if the local machine is not NixOS (`! -e /etc/NIXOS`) or `hostname -s != CONFIG`, `TARGET` auto-resolves to `CONFIG` so remote deployment occurs transparently.
3. **Privilege Elevation Guard**:
   - Local Darwin `test` and `switch` MUST invoke `sudo`.
   - Local NixOS `test`, `switch`, and `boot` MUST invoke `nh os` (which elevates automatically) or `sudo nixos-rebuild`.
   - Remote NixOS `test`, `switch`, and `boot` MUST invoke `nh os ... --elevation-strategy passwordless --target-host "${TARGET}"` or `nixos-rebuild ... --target-host "${TARGET}" --use-remote-sudo`.
   - Initial bare-metal `install` MUST prefix `root@` to `target` when `@` is absent and invoke `nixos-anywhere`.
