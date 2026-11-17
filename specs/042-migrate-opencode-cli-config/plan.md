# Implementation Plan: Migrate OpenCode CLI Configuration

**Branch**: `042-migrate-opencode-cli-config` | **Date**: 2026-11-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/042-migrate-opencode-cli-config/spec.md`

## Summary

Migrate the OpenCode configuration in `modules/services/opencode.nix` from legacy `programs.opencode.tui` to modern `programs.opencode.cli`, resolving the Home Manager evaluation warning emitted during NixOS host evaluation and deployment (`just switch` on `desktop-pc`). Ensure that the Nord visual theme remains active across all environments (`desktop-pc` via Home Manager, and `homelab` via systemd-tmpfiles).

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable, Flake-parts)

**Primary Dependencies**:
- `home-manager` (`programs.opencode.cli` module option)
- `inputs.opencode` (OpenCode v2.1.4 pinned package)
- `systemd.tmpfiles.rules` (Declarative store symlinks for `homelab`)
- `flake-parts` & `import-tree` (Dendritic module discovery)

**Storage**:
- Generated JSON derivation in `/nix/store`
- Deployed at `$HOME/.config/opencode/cli.json`

**Testing**:
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Hermetic flake checks: `just check` (`nix flake check`)
- Multi-host evaluation:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath`
- Activation testing: `just test configuration="desktop-pc"`

**Target Platform**:
- `desktop-pc` (`x86_64-linux` NixOS desktop workstation)
- `homelab` (`x86_64-linux` NixOS headless server)
- `macbook-air-m4-15` (`aarch64-darwin` macOS laptop)

**Project Type**: Infrastructure as Code (Nix Flakes, NixOS modules, Home Manager)

**Performance Goals**:
- 0 evaluation warnings emitted across all targets (`SC-001`, `SC-002`)
- 100% theme retention (`nord`) across interactive CLI sessions (`SC-003`)
- Clean activation and build across all machines (`SC-004`)

**Constraints**:
- Must adhere to Constitution Principle I (Declarative) & II (Dendritic Colocation)
- Must not touch `modules/hosts/` (keep host declarations pure)
- Must preserve `enableHomeManager = false` on `homelab`

**Scale/Scope**:
- 1 modified module: `modules/services/opencode.nix`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | `cli.json` is 100% declared in Nix expressions; deployed via Home Manager and read-only `/nix/store` symlinks. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Colocated directly in `modules/services/opencode.nix`. Host declarations remain untouched; `homelab` retains `enableHomeManager = false`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Formatted with `alejandra`, verified with `statix`, `deadnix`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | No secrets involved; client settings only govern theme styling. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Validated via `nix eval` and `just test` prior to `just switch`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for modified services; dual Bash/Fish parity | **PASS** | Quickstart and documentation provide dual Bash and Fish command instructions. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`042-migrate-opencode-cli-config`), no direct commits to `main` | **PASS** | Isolated on branch `042-migrate-opencode-cli-config`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/042-migrate-opencode-cli-config/
├── spec.md              # Feature specification
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Phase 0 output (/speckit.plan output)
├── data-model.md        # Phase 1 output (/speckit.plan output)
├── quickstart.md        # Phase 1 output (/speckit.plan output)
├── contracts/           # Phase 1 output (/speckit.plan output)
│   └── opencode-cli-contract.md
└── checklists/
    └── requirements.md  # Quality validation checklist
```

### Source Code (repository root)

```text
modules/
└── services/
    └── opencode.nix     # Update Home Manager programs.opencode.cli and tmpfiles cli.json
```

**Structure Decision**: Modifications are confined to `modules/services/opencode.nix`, respecting the existing Dendritic layout.

---

## Complexity Tracking

> **No Constitution violations. Zero exceptions or justifications needed.**
