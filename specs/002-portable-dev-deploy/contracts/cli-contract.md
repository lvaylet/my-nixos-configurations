# CLI Interface Contract: Operational Task Runner & Deployment Recipes

**Feature**: Portable Multi-Environment Development, Testing, and Deployment (`002-portable-dev-deploy`)
**Date**: 2026-08-12
**Status**: Completed

## 1. Justfile Recipes Contract

All operations are orchestrated through `justfile` recipes with standardized parameter signatures.

### 1.1 Recipe Signatures & Behaviors

#### `build [configuration="desktop-pc"] [target=""]`

- **Purpose**: Build the NixOS toplevel system closure for the designated machine configuration.
- **Parameters**:
  - `configuration` (string, default: `"desktop-pc"`): Target NixOS configuration name (`desktop-pc`, `homelab`, `iso`).
  - `target` (string, default: `""`): Optional remote SSH host string.
- **Behavior Matrix**:

  | Host OS | Target Argument | Executed Command | Description |
  | :--- | :--- | :--- | :--- |
  | **NixOS** | `""` | `nh os build .#{{configuration}}` | Local build via Nix helper |
  | **Non-NixOS Linux** | `""` | `nix build .#nixosConfigurations.{{configuration}}.config.system.build.toplevel` | Local closure build without system profile modification |
  | **Any Linux** | `"homelab"` | `nixos-rebuild build --flake .#{{configuration}} --target-host {{target}}` | Remote build on / for remote host |

---

#### `switch [configuration="desktop-pc"] [target=""]`

- **Purpose**: Build, activate, and set the system configuration as the default boot profile.
- **Parameters**:
  - `configuration` (string, default: `"desktop-pc"`): Configuration name.
  - `target` (string, default: `""`): Remote SSH host string (e.g. `"homelab"`, `"user@192.168.1.50"`).
- **Behavior Matrix**:

  | Host OS | Target Argument | Executed Command | Description |
  | :--- | :--- | :--- | :--- |
  | **NixOS** | `""` | `nh os switch .#{{configuration}}` | Local profile switch |
  | **Non-NixOS Linux** | `""` | Error & exit code 1 | Guard message explaining remote target requirement |
  | **Any Linux** | `"homelab"` | `nixos-rebuild switch --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo` | Remote build, copy, and switch over SSH |

---

#### `test [configuration="desktop-pc"] [target=""]`

- **Purpose**: Build and activate configuration changes temporarily without modifying the bootloader.
- **Parameters**:
  - `configuration` (string, default: `"desktop-pc"`): Configuration name.
  - `target` (string, default: `""`): Remote SSH host string.
- **Behavior Matrix**:

  | Host OS | Target Argument | Executed Command | Description |
  | :--- | :--- | :--- | :--- |
  | **NixOS** | `""` | `nh os test .#{{configuration}}` | Local non-switching activation |
  | **Non-NixOS Linux** | `""` | Error & exit code 1 | Guard message explaining remote target requirement |
  | **Any Linux** | `"homelab"` | `nixos-rebuild test --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo` | Remote non-switching activation over SSH |

---

#### `boot [configuration="desktop-pc"] [target=""]`

- **Purpose**: Build and set the configuration as default for the next boot without immediate live activation.
- **Parameters**:
  - `configuration` (string, default: `"desktop-pc"`): Configuration name.
  - `target` (string, default: `""`): Remote SSH host string.
- **Behavior Matrix**:

  | Host OS | Target Argument | Executed Command | Description |
  | :--- | :--- | :--- | :--- |
  | **NixOS** | `""` | `nh os boot .#{{configuration}}` | Local bootloader entry creation |
  | **Non-NixOS Linux** | `""` | Error & exit code 1 | Guard message explaining remote target requirement |
  | **Any Linux** | `"homelab"` | `nixos-rebuild boot --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo` | Remote bootloader entry creation over SSH |

---

## 2. Standard Exit Codes & Error Outputs

| Condition | Exit Code | Stdout / Stderr Output Contract |
| :--- | :--- | :--- |
| **Success** | `0` | Command output from `nh` / `nix build` / `nixos-rebuild` |
| **Non-NixOS Local Switch Guard** | `1` | `Error: Local system is not NixOS. To deploy to a remote host, specify target (e.g., just switch <config> <target>)` |
| **SSH Connection Failure** | `255` | `ssh: connect to host <target> port 22: Connection refused / timed out` |
| **Nix Evaluation / Syntax Error** | `1` | Nix evaluation trace pointing to file and line number |
