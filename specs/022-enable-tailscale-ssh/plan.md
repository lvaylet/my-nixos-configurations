# Implementation Plan: Dynamic Tailnet SSH Access Without Static Key Distribution

**Branch**: `022-enable-tailscale-ssh` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/022-enable-tailscale-ssh/spec.md`

## Summary

Enable Tailscale SSH declaratively across NixOS hosts importing `services.tailscale` (`homelab`, `desktop-pc`) so that any device authenticated to the private tailnet can establish SSH sessions as `laurent` or `root` via Tailscale identity and ACLs—without generating, distributing, or committing static SSH public keys for new client machines.

Technical approach:

1. Update `modules/services/tailscale.nix` to set `services.tailscale.extraSetFlags = ["--ssh"];` and configure `systemd.services.tailscaled-set` (`wantedBy = ["multi-user.target"]`, `partOf = ["tailscaled.service"]`, `serviceConfig.RemainAfterExit = true`) so `tailscale set --ssh` runs immediately on live `nixos-rebuild switch` as well as on boot/restart.
2. Preserve existing OpenSSH (`modules/services/ssh.nix`) and static `authorizedKeys` (`modules/core/base.nix`, `modules/hosts/homelab.nix`) intact so physical LAN SSH connections (`192.168.1.180`) remain available as a resilient local fallback.
3. Update `README.md` to document Tailscale SSH usage, the required Tailscale Admin Console `ssh` ACL policy, physical LAN fallback coexistence, and dual **Bash** and **Fish** command variants where applicable.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `nixpkgs` (NixOS `services.tailscale` and `services.openssh` modules)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)

**Storage**:

- Persistent Tailscale state on `tailscaled` (`/var/lib/tailscale`)
- Persistent SSH host keys on `homelab` under `/persistent/etc/ssh/` via `modules/core/preservation.nix`

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake evaluation & pre-commit checks: `just check` (`nix flake check`)
- Targeted attribute evaluation:
  - `nix eval .#nixosConfigurations.homelab.config.services.tailscale.extraSetFlags --json`
  - `nix eval .#nixosConfigurations.homelab.config.systemd.services.tailscaled-set.script --raw`
  - `nix eval .#nixosConfigurations.desktop-pc.config.services.tailscale.extraSetFlags --json`

**Target Platform**: NixOS (`x86_64-linux`) for `homelab` and `desktop-pc`

**Project Type**: Infrastructure as Code / NixOS Multi-Host Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero additional boot block: `tailscaled-set.service` runs asynchronously (`Type = "oneshot"`) after `tailscaled.service` starts.
- Clean flake evaluation across all configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`).

**Constraints**:

- Strict Dendritic Pattern compliance: Tailscale SSH is configured inside `modules/services/tailscale.nix` with zero inline service rules in `modules/hosts/homelab.nix`.
- Non-breaking LAN fallback: OpenSSH (`services.openssh`) and static `authorizedKeys` remain active on physical interfaces (`192.168.1.180`).
- Zero secrets in Git: No auth keys or private credentials committed.
- Living documentation: `README.md` updated in the same branch with dual Bash/Fish parity.

**Scale/Scope**:

- 1 modified feature module: `modules/services/tailscale.nix`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | `services.tailscale.extraSetFlags = ["--ssh"]` declaratively generates `tailscaled-set.service` instead of relying on imperative `tailscale set --ssh` CLI calls. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | Change is encapsulated entirely in `modules/services/tailscale.nix`; host files (`homelab.nix`, `desktop-pc.nix`) require zero inline overrides. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials or private keys in repo | **PASS** | Authentication uses Tailscale node identity and ACLs; zero secrets added to repository. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | `tailscaled-set` unit generation and top-level host closures are verified via `nix eval` and `just check`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` updated with Tailscale SSH instructions, ACL policy configuration, and dual Bash/Fish snippets where syntax differs. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | All work is isolated on branch `022-enable-tailscale-ssh`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/022-enable-tailscale-ssh/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── tailscale-ssh-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix                   # Unchanged (retains static SSH authorizedKeys for LAN fallback)
│   └── vars.nix                   # Unchanged (retains static SSH public key variables)
├── services/
│   ├── ssh.nix                    # Unchanged (retains OpenSSH daemon & client LAN alias)
│   └── tailscale.nix              # Updated: add extraSetFlags = ["--ssh"]
└── hosts/
    ├── desktop-pc.nix             # Unchanged (consumes services.tailscale)
    ├── homelab.nix                # Unchanged (consumes services.tailscale)
    └── macbook-air-m4-15.nix      # Unchanged (client workstation)
README.md                          # Updated: document Tailscale SSH & ACL policy
```

**Structure Decision**: Single declarative Nix flake repository following the Dendritic Pattern (`modules/services/tailscale.nix` + `README.md`).

---

## Complexity Tracking

No constitutional violations. Complexity tracking not required.
