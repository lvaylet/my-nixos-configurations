# Implementation Plan: Homelab Configuration Integration

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-integrate-homelab-config/spec.md`

## Summary

Integrate the reference homelab configuration from `my-first-impermanent-nixos-setup-with-disko-and-preservation` into `hosts/homelab` within this repository. The implementation incorporates declarative disk partitioning (`disko`) with an ephemeral in-RAM root (`tmpfs`), persistent Btrfs subvolumes (`/persistent` and `/nix`), dedicated swap, and state preservation (`preservation`). Hardware specifications are tuned specifically for the Intel N150 processor (ZRAM swap, Intel microcode, `schedutil` governor, Intel QuickSync graphics drivers, and scheduled SSD TRIM). Application services (Filebrowser Quantum, Home Assistant, Portainer, Jellyfin, qBittorrent, and `nix-ld`) are integrated as dendritic feature modules under `modules/services/` with colocated preservation rules, coordinated multimedia access controls (SetGID `2775`, systemd tmpfiles `z` mop-up rules), and 100% verbatim retention of all explanatory comments.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `disko` (`github:nix-community/disko`)
- `preservation` (`github:nix-community/preservation`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)
- `home-manager` (`github:nix-community/home-manager`)
- `git-hooks` (`github:cachix/git-hooks.nix`)

**Storage**: Declarative Disko hybrid partitioning (in-RAM `tmpfs` root, Btrfs subvolumes `/persistent` and `/nix`, dedicated 4 GB swap, 1 GB ESP `/boot`), with declarative persistence mapped to `/persistent`.

**Testing**:

- Formatting & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Regression evaluation: `desktop-pc` and `iso` toplevel evaluation.
- Pre-commit sandboxes: `just check` (`nix flake check`).

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:

- Ephemeral reboot with clean state in RAM.
- Virtual memory expansion to ~24 GB usable space via ZRAM compressed swap (zstd algorithm, 50% RAM).
- Hardware-accelerated media transcoding via Intel QuickSync iGPU drivers (`intel-media-driver`).
- Minimized NVMe write wear via weekly `fstrim` and Btrfs `noatime, compress=zstd, ssd, discard=async`.

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` must only assemble hardware and feature modules, with zero inline service definitions.
- 100% of explanatory comments from the source repository must be preserved verbatim.
- Zero plaintext secrets committed to version control.
- No regressions on `desktop-pc` or `iso` targets.

**Scale/Scope**:

- 1 target host updated: `modules/hosts/homelab.nix`.
- 1 hardware and partitioning profile updated: `modules/hosts/_hardware/homelab.nix`.
- 1 shared identity module updated: `modules/core/vars.nix`.
- 1 core preservation module added: `modules/core/preservation.nix`.
- 1 helper builder updated: `modules/core/lib.nix` (wiring `disko` and `preservation`).
- 6 service modules updated/added: `filebrowser.nix`, `home-automation.nix`, `jellyfin.nix`, `qbittorrent.nix`, `media.nix`, `portainer.nix`, `nix-ld.nix`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | `disko` and `preservation` added as pinned flake inputs following `nixpkgs`. System runs on ephemeral root with pure declarative preservation. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | All services reside under `modules/services/` with colocated preservation rules. `modules/hosts/homelab.nix` only composes features via `mkHost`. Hardware remains isolated in `_hardware/`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All Nix modules verified to format cleanly with `alejandra` and pass static analysis checks without dead code or warnings. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | SHA-512 password hash retained; root login restricted to authorized SSH public keys (`PermitRootLogin = "prohibit-password"`). |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Flake evaluation and sandbox checks documented in `quickstart.md` before applying to real hardware. |

---

## Project Structure

### Documentation (this feature)

```text
specs/006-integrate-homelab-config/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── disko-preservation-contract.md
│   ├── multimedia-storage-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification & clarifications
```

### Source Code (repository root)

```text
flake.nix                               # Pinned flake inputs (disko, preservation)
modules/
├── core/
│   ├── vars.nix                        # Centralized identity (personal + work SSH keys)
│   ├── lib.nix                         # mkHost helper (includes disko & preservation modules)
│   ├── base.nix                        # Core operating system foundation
│   └── preservation.nix                # System & user-level state preservation rules
├── services/
│   ├── media.nix                       # Multimedia group (995), user UIDs, SetGID, tmpfiles z rules
│   ├── filebrowser.nix                 # Filebrowser Quantum OCI container + preservation
│   ├── home-automation.nix             # Home Assistant OCI container + preservation
│   ├── portainer.nix                   # Portainer CE OCI container + preservation
│   ├── jellyfin.nix                    # Jellyfin native service + multimedia group + preservation
│   ├── qbittorrent.nix                 # qBittorrent native service + serverConfig + preservation
│   ├── nix-ld.nix                      # Dynamic binary loader for unpatched tools & VS Code
│   ├── podman.nix                      # Podman container engine + DNS + auto-prune + preservation
│   ├── network.nix                     # Networking & firewall configuration
│   ├── ssh.nix                         # OpenSSH server daemon
│   └── ssd.nix                         # General SSD optimizations
└── hosts/
    ├── homelab.nix                     # Host composition (hardware + enabled feature modules)
    └── _hardware/
        └── homelab.nix                 # Hardware scan, Intel N150 tuning, and Disko hybrid layout
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. All services are organized in `modules/services/` with colocated preservation declarations, hardware and Disko layout are isolated in `modules/hosts/_hardware/homelab.nix` (ignored by automatic discovery), and shared identity options reside in `modules/core/vars.nix`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–V | N/A |
