# Implementation Plan: Persist Tailscale Node Identity and State Across Impermanent Reboots

**Branch**: `023-persist-tailscale-state` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/023-persist-tailscale-state/spec.md`

## Summary

Persist `/var/lib/tailscale` under `/persistent` on impermanent NixOS hosts (`homelab`) by registering the directory in `modules/services/tailscale.nix` via `preservation.preserveAt."/persistent".directories = lib.mkIf config.services.tailscale.enable [...]` with `user = "root"`, `group = "root"`, and `mode = "0700"`.

Technical approach:

1. Update `modules/services/tailscale.nix` to accept `{config, lib, ...}:` in its `nixos` module function and declare `preservation.preserveAt."/persistent".directories` guarded by `lib.mkIf config.services.tailscale.enable` for `/var/lib/tailscale` (`user = "root"`, `group = "root"`, `mode = "0700"`).
2. Keep existing Tailscale settings (`enable = true`, `permitCertUid = "caddy"`, `extraSetFlags = ["--ssh"]`, and `systemd.services.tailscaled-set`) intact.
3. Update `README.md` (`Homelab Hosted Services` and `Tailscale SSH Access Control Policy` sections) to document `/var/lib/tailscale` state preservation under `/persistent/var/lib/tailscale` across ephemeral `tmpfs` reboots, maintaining dual **Bash** and **Fish** command parity.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `nixpkgs` (NixOS `services.tailscale` module)
- `preservation` (`github:nix-community/preservation`, imported into all NixOS hosts via `modules/core/lib.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)

**Storage**:

- Persistent Btrfs subvolume `/persistent` on `homelab`, bind-mounting `/persistent/var/lib/tailscale` to `/var/lib/tailscale` (`root:root`, `0700`)

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake evaluation & pre-commit checks: `just check` (`nix flake check`)
- Targeted attribute evaluation:
  - `nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".directories --json`
  - `nix eval .#nixosConfigurations.desktop-pc.config.preservation.enable --json`
  - `nix eval .#nixosConfigurations.homelab.config.services.tailscale.enable --json`

**Target Platform**: NixOS (`x86_64-linux`) for `homelab` (impermanent root) and `desktop-pc` (persistent root)

**Project Type**: Infrastructure as Code / NixOS Multi-Host Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero boot latency overhead beyond a standard local bind mount (`var-lib-tailscale.mount`) ordered before `tailscaled.service`.
- Clean flake evaluation across all configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`).

**Constraints**:

- Strict Dendritic Pattern compliance: Tailscale state preservation is colocated inside `modules/services/tailscale.nix` with zero inline service rules in `modules/hosts/homelab.nix` or `modules/core/preservation.nix`.
- Strict directory permissions (`root:root`, `0700`) to protect the node private key in `/var/lib/tailscale/tailscaled.state`.
- Zero secrets in Git: No node keys or auth tokens committed.
- Living documentation: `README.md` updated in the same branch with dual Bash/Fish parity.

**Scale/Scope**:

- 1 modified feature module: `modules/services/tailscale.nix`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | `/var/lib/tailscale` persistence is declared purely via `preservation.preserveAt."/persistent".directories` in `modules/services/tailscale.nix`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | Preservation mapping is colocated directly inside `modules/services/tailscale.nix` matching `caddy.nix`, `podman.nix`, `opencode.nix`, and `uptime-kuma.nix`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials or private keys in repo; strict runtime permissions | **PASS** | Enforces `0700` (`root:root`) on `/var/lib/tailscale` so `tailscaled.state` is protected on disk; zero secrets committed to Git. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | Verified via `nix eval` of `homelab` and `desktop-pc` preservation/Tailscale attributes and `just check`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` updated to document `/var/lib/tailscale` persistence under `/persistent/var/lib/tailscale` with dual Bash/Fish snippets. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | All work is isolated on branch `023-persist-tailscale-state`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/023-persist-tailscale-state/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── tailscale-preservation-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── lib.nix                    # Unchanged (injects inputs.preservation.nixosModules.default into NixOS hosts)
│   └── preservation.nix           # Unchanged (enables preservation.enable = true on homelab)
├── services/
│   ├── caddy.nix                  # Unchanged (consumes Tailscale LocalAPI via permitCertUid = "caddy")
│   └── tailscale.nix              # Updated: add preservation.preserveAt."/persistent".directories for /var/lib/tailscale
└── hosts/
    ├── desktop-pc.nix             # Unchanged (consumes services.tailscale; preservation.enable remains false)
    └── homelab.nix                # Unchanged (consumes core.preservation + services.tailscale)
README.md                          # Updated: document /var/lib/tailscale persistence under /persistent
```

**Structure Decision**: Single declarative Nix flake repository following the Dendritic Pattern (`modules/services/tailscale.nix` + `README.md`).

---

## Complexity Tracking

No constitutional violations. Complexity tracking not required.
