# Implementation Plan: Harmonized Visual Studio Code and Code Server Configurations

**Branch**: `036-harmonize-vscode-codeserver` | **Date**: 2026-10-31 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/036-harmonize-vscode-codeserver/spec.md`

## Summary

Harmonize the configurations of Visual Studio Code (on `desktop-pc`) and Code Server (on `homelab`) by establishing a centralized, single source of truth in `modules/core/vscode.nix`. This eliminates code duplication across hosts while achieving maximum visual, functional, and extension parity.

Key technical implementation components:

1. **Centralized Configuration Library (`modules/core/vscode.nix`)**: Discovered automatically via `import-tree ./modules`, declaring `config.flake.lib.vscode` with shared `settings` (Nord theme, FiraCode Nerd Font, relative line numbers, rulers, format-on-save, diff options, file associations, Nix LSP rules) and `extensions` (GitHub Actions, GitHub Pull Requests, Nord theme, Markdownlint, Nix IDE, Nix, Alejandra, Even Better TOML).
2. **Desktop Consumer Refactoring (`modules/desktop/editors.nix`)**: Replaces 80+ lines of duplicate settings and package lists in Home Manager's `programs.vscode.profiles.default` with references to `outputs.lib.vscode.settings` and `outputs.lib.vscode.extensions pkgs`, while retaining desktop-only tools (`wl-clipboard`, Zed editor).
3. **Homelab Extension Packaging (`modules/services/code-server.nix`)**: Packages Code Server with all shared extensions pre-installed using `pkgs.vscode-with-extensions.override { vscode = pkgs.code-server; vscodeExtensions = outputs.lib.vscode.extensions pkgs; }`.
4. **Homelab Declarative Settings Symlinks**: Enforces `outputs.lib.vscode.settings` on `homelab` without Home Manager using `systemd.tmpfiles.rules` (`L+`) pointing to a generated JSON derivation in `/nix/store`.
5. **Toolchain Parity**: Adds `alejandra` and `nixd` to `services.code-server.extraPackages` so Nix formatting and language server diagnostics work in Code Server out of the box.
6. **Documentation Synchronization**: Updates `README.md` to document the unified editor configuration and shared feature set with dual Bash and Fish command instructions.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable, Flake-parts)

**Primary Dependencies**:

- `pkgs.vscode-with-extensions` (Hermetic wrapper for VS Code / Code Server extensions)
- `pkgs.code-server` (Web-based IDE service in `modules/services/code-server.nix`)
- `pkgs.vscode-extensions` (Curated extension derivations from Nixpkgs)
- `pkgs.nixd` & `pkgs.alejandra` (Nix language server and formatter)
- `home-manager` (`programs.vscode` on `desktop-pc` and `macbook-air-m4-15`)
- `systemd.tmpfiles.rules` (Declarative store symlinks on `homelab`)
- `flake-parts` & `import-tree` (Dendritic module auto-discovery)

**Storage**:

- Immutable Nix store derivations:
  - Settings JSON generated via `(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings`
  - Wrapped `code-server-with-extensions` package in `/nix/store`
- Persisted user state on `homelab` under `/persistent/home/laurent`:
  - `~/.local/share/code-server`
  - `~/.config/code-server`

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Hermetic sandbox checks: `just check` (`nix flake check`).
- Target host evaluation:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath`
- Activation testing: `just test configuration="homelab"`, `just test configuration="desktop-pc"`.

**Target Platform**:

- `desktop-pc` (`x86_64-linux` NixOS workstation)
- `homelab` (`x86_64-linux` NixOS headless server)
- `macbook-air-m4-15` (`aarch64-darwin` macOS laptop)

**Project Type**: Infrastructure as Code (Nix Flakes, NixOS system configuration, Home Manager).

**Performance Goals**:

- 0 lines of duplicated VS Code settings JSON across the repository (`SC-002`).
- 100% parity of theme, typography, formatting, and extensions between desktop and web editors (`SC-001`, `SC-003`).
- 0 evaluation or build regressions across all target hosts (`SC-004`).
- Zero delay in extension availability on `homelab` (extensions pre-bundled in package wrapper).

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/core/vscode.nix` auto-discovered by `import-tree ./modules` (Principle II).
- `homelab` MUST keep `enableHomeManager = false` (Principle II).
- Desktop GUI tools (`wl-clipboard`, `zed-editor`) MUST NOT leak onto `homelab`.
- Living documentation updated in same branch with dual Bash/Fish syntax (Principle VI).
- Dedicated branch workflow: Changes isolated to branch `036-harmonize-vscode-codeserver` (Principle VII).

**Scale/Scope**:

- 1 new core module: `modules/core/vscode.nix`.
- 2 updated feature modules: `modules/desktop/editors.nix`, `modules/services/code-server.nix`.
- 1 updated documentation file: `README.md`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Shared settings and extensions are 100% declared in Nix expressions; deployed via read-only `/nix/store` symlinks and wrapped package derivations. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/core/vscode.nix` is discovered via `import-tree ./modules` contributing to `config.flake.lib.vscode`. Host declarations remain untouched; zero inline definitions. `homelab` retains `enableHomeManager = false`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All modified files formatted with `alejandra`, checked with `statix` and `deadnix`, and verified with `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | No secrets or credentials involved in editor preferences, themes, or extension manifests. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Validation scenarios in `quickstart.md` mandate flake evaluation and `just test` before switching live profile. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for modified services; dual Bash/Fish parity | **PASS** | `README.md` updates contracted with dual Bash/Fish commands. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`036-harmonize-vscode-codeserver`), no direct commits to `main` | **PASS** | All modifications occur on dedicated branch `036-harmonize-vscode-codeserver`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/036-harmonize-vscode-codeserver/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Phase 0 output (/speckit.plan output)
├── data-model.md        # Phase 1 output (/speckit.plan output)
├── quickstart.md        # Phase 1 output (/speckit.plan output)
├── contracts/           # Phase 1 output (/speckit.plan output)
│   ├── shared-vscode-contract.md
│   ├── code-server-service-contract.md
│   └── desktop-editors-contract.md
└── checklists/
    └── requirements.md  # Quality validation checklist
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── lib.nix                          # Flake composition helpers (mkHost passing outputs in specialArgs)
│   ├── vars.nix                         # Centralized identity options
│   └── vscode.nix                       # NEW: Shared VS Code settings & extensions library
├── desktop/
│   └── editors.nix                      # REFACTORED: Consumes outputs.lib.vscode; removes duplicates
├── services/
│   └── code-server.nix                  # REFACTORED: Wraps code-server with shared extensions & symlinks settings
└── hosts/
    ├── desktop-pc.nix                   # Unchanged (features include desktop.editors)
    └── homelab.nix                      # Unchanged (features include services.code-server)
```

**Structure Decision**:

- Created `modules/core/vscode.nix` to hold the single source of truth for VS Code settings and extension lists.
- Updated `modules/desktop/editors.nix` to consume `outputs.lib.vscode` inside Home Manager.
- Updated `modules/services/code-server.nix` to consume `outputs.lib.vscode` inside native NixOS, using `vscode-with-extensions` and `systemd.tmpfiles.rules`.
- Living documentation updated in `README.md`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | All principles satisfied without violations | N/A |
