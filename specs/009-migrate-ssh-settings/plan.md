# Implementation Plan: Migrate SSH Settings from Deprecated MatchBlocks

**Branch**: `009-migrate-ssh-settings` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/009-migrate-ssh-settings/spec.md`

## Summary

Migrate the user SSH client configuration in `modules/services/ssh.nix` from the deprecated `programs.ssh.matchBlocks` option to the modern `programs.ssh.settings` structure. This eliminates the persistent `evaluation warning: laurent profile: 'programs.ssh.matchBlocks' ... is deprecated. Use 'programs.ssh.settings'.` emitted during every system evaluation and build, while preserving full parameter and connection parity for all defined remote hosts (`rpi3` and `homelab-vm`).

---

## Technical Context

**Language/Version**: Nix (Nixpkgs unstable, Flakes)

**Primary Dependencies**:
- `home-manager` (`github:nix-community/home-manager`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)
- OpenSSH client suite

**Storage**: Declarative user configuration symlinked to `~/.ssh/config` via Home Manager.

**Testing**:
- Evaluation diagnostics verification: `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` (ensuring 0 warnings emitted).
- Configuration content diffing: `nix eval --raw .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file.".ssh/config".text`.
- Formatting & static linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Hermetic pre-commit checks: `just check` (`nix flake check`).

**Target Platform**: Multi-target Linux infrastructure (`desktop-pc`, `homelab`, `iso`).

**Project Type**: Infrastructure as Code (Nix Flakes, Home Manager module).

**Performance Goals**:
- 0 evaluation duration increase.
- 100% elimination of evaluation warnings on all build and check operations.

**Constraints**:
- Strict functional parity: identical IP addresses, usernames, identity files, and security options rendered to `~/.ssh/config`.
- Adherence to repository constitution quality gates (I, II, III, IV, V).
- Zero secrets or private keys committed.

**Scale/Scope**: 1 module modification (`modules/services/ssh.nix`), 1 primary user profile (`laurent`), 2 remote host profiles (`rpi3`, `homelab-vm`).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Pinned `flake.lock`, purely declarative configuration, no imperative drift | **PASS** | SSH configuration remains 100% declarative via Home Manager module; no imperative changes to `$HOME`. |
| **II. Dendritic Modularity** | Feature-centric colocation under `modules/services/`, zero boilerplate | **PASS** | Colocated within `modules/services/ssh.nix` in the dendritic architecture; discovered automatically via `import-tree`. |
| **III. Shift-Left Quality** | Clean formatting (`alejandra`), zero `statix`/`deadnix` errors, clean pre-commit hooks | **PASS** | Formatted via `alejandra`, checked with `statix` and `deadnix`, verified via `just check` / `nix flake check` with zero warnings. |
| **IV. Zero-Secrets Leakage** | No private keys or credentials in plaintext | **PASS** | Only public file paths (`~/.ssh/id_ed25519`) referenced; zero credentials committed. |
| **V. Rigorous Verification** | Safe evaluation, `just check`, non-destructive testing before activation | **PASS** | Validated via `nix eval` diagnostics inspection and `just check` before system profile activation. |

---

## Project Structure

### Documentation (this feature)

```text
specs/009-migrate-ssh-settings/
├── plan.md              # Implementation Plan (/speckit.plan command output)
├── research.md          # Technical research and design decisions (Phase 0)
├── data-model.md        # Entities, attributes, and relationships (Phase 1)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   └── ssh-settings-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
└── services/
    └── ssh.nix          # Dendritic OpenSSH daemon and client module
```

**Structure Decision**: Modifies the existing dendritic module `modules/services/ssh.nix` in place, updating the `homeManager` attribute set to use `programs.ssh.settings` rather than `programs.ssh.matchBlocks`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *None* | N/A | No constitution violations detected. Standard migration to upstream Home Manager option schema. |
