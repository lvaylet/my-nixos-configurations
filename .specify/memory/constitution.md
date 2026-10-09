<!--
Sync Impact Report:
- Version change: 1.0.1 -> 2.0.0
- List of modified principles:
  - II. Dendritic Modularity & Feature-Centric Composition (ratified migration from host/module directory silos to the Dendritic Pattern using flake-parts and import-tree, feature-centric colocation of NixOS and Home Manager settings, zero-boilerplate module discovery, and centralized config.flake.vars options).
- Structural & Architectural Constraints:
  - Standardized repository hierarchy updated to reflect the dendritic domain hierarchy under modules/ (core/, desktop/, services/, hosts/).
- Follow-up TODOs: None
-->

# my-nixos-configurations Constitution

## Core Principles

### I. Declarative & Hermetic Configuration (NON-NEGOTIABLE)
All system infrastructure, machine configurations, and user environments MUST be declared purely and reproducibly via Nix flakes, NixOS modules, and Home Manager. Imperative, ad-hoc state changes in `$HOME` or `/etc` are strictly prohibited unless managed by Nix or explicitly documented as transient runtime data. Flake inputs MUST be strictly managed and pinned via `flake.lock`, with auxiliary inputs (`home-manager`, `nvf`, `git-hooks`) configured to follow `nixpkgs` whenever supported.

*Rationale*: Guarantees total reproducibility across physical and virtual targets (`desktop-pc`, `homelab`, `iso`) and eliminates configuration drift across boots and reinstalls.

### II. Dendritic Modularity & Feature-Centric Composition
Configurations MUST follow the **Dendritic Pattern**: every non-entrypoint file is a top-level module discovered automatically via `import-tree ./modules` and evaluated by `flake-parts`. Capabilities MUST be organized into cohesive, domain-grouped features under `modules/` (`core/`, `desktop/`, `services/`), colocating NixOS system services and Home Manager user environments within the same feature scope where applicable. Host configurations (`modules/hosts/`) MUST only assemble hardware specifications (`modules/hosts/_hardware/`) and declare their enabled feature set; they MUST NOT contain inline service definitions. Shared identity parameters (usernames, email addresses, SSH public keys) MUST be declared as top-level options in `modules/core/vars.nix` (`config.flake.vars`) and accessed without parameter plumbing.

*Rationale*: Eliminates directory silos and import-wiring boilerplate, colocates system and user concerns per capability, maximizes modular reusability across hosts, and guarantees consistent updates to shared identity properties.

### III. Shift-Left Quality, Formatting & Static Analysis
All Nix expressions MUST format cleanly with `alejandra` (`nix fmt`) and pass static linting (`statix check`) and dead-code detection (`deadnix`) with zero errors or warnings. Pre-commit hooks (`git-hooks.nix`) MUST run hermetically in isolated Nix sandbox checks (`nix flake check` / `just check`) and MUST succeed with exit code 0. File hygiene rules—including trailing whitespace elimination, mixed line ending prevention, case-conflict checks, proper script permissions, and end-of-file formatting—are mandatory and non-negotiable across all code, specifications, and metadata files.

*Rationale*: Enforces consistent code style across the repository, eliminates unreferenced bindings early, and guarantees flake integrity and build correctness before commits are made.

### IV. Zero-Secrets Leakage & Security First
Secrets, credentials, and private keys MUST NEVER be committed to version control in plaintext. All commits MUST pass automated secret detection filters (`ripsecrets`, `trufflehog`, `detect-private-keys`, and `pre-commit-hook-ensure-sops`). Password hashes for declarative user accounts MUST be created with strong cryptographic algorithms (e.g. `mkpasswd -m sha-512`) or referenced via secure runtime secrets mechanisms (e.g., SOPS / `sops-nix`).

*Rationale*: Protects personal credentials, private keys, and infrastructure tokens against accidental leakage in local and public repositories.

### V. Rigorous Verification & Safe Deployment Workflow
Every configuration change MUST be verified prior to permanent activation. Changes MUST pass flake evaluation and sandbox checks (`just check` / `nix flake check` succeeding with exit code 0) and safe non-switching activation testing (`just test` / `nh os test`) before switching the live profile (`just switch` / `nh os switch`). `justfile` serves as the single source of truth for all operational recipes. State versions (`system.stateVersion` and `home.stateVersion`) MUST remain pinned to their initial deployment release and MUST NOT be bumped without reviewing upstream release notes.

*Rationale*: Prevents unbootable systems, broken desktop sessions, and unintentional data migrations or regressions.

## Structural & Architectural Constraints

The repository adheres to a standardized hierarchy that MUST be respected:

1. **Root Flake (`flake.nix`)**:
   - Pinned inputs, invokes `flake-parts.lib.mkFlake` with `(inputs.import-tree ./modules)`.
2. **Core Domain (`modules/core/`)**:
   - `systems.nix`: Target systems list (`x86_64-linux`, etc.).
   - `vars.nix`: Centralized identity options (`config.flake.vars`).
   - `lib.nix`: Shared composition helpers (`mkHost`).
   - `base.nix`: Base operating system foundation.
   - `checks.nix`, `formatter.nix`, `devshell.nix`: Multi-system developer tooling.
3. **Desktop Domain (`modules/desktop/`)**:
   - Encapsulates graphical sessions, Wayland compositors (Niri), shells (Noctalia), terminal (WezTerm), Fish shell, fonts, editors (nvf, VS Code, Zed), audio, and graphics.
4. **Services Domain (`modules/services/`)**:
   - Encapsulates system daemons, server services (Jellyfin, QBittorrent, Filebrowser, AdGuard Home), networking, OpenSSH, Tailscale, Podman, and virtualization.
5. **Host Definitions (`modules/hosts/`)**:
   - Target declarations (`desktop-pc.nix`, `homelab.nix`, `iso.nix`) composing hardware with selected feature modules.
   - Hardware configurations reside under `modules/hosts/_hardware/` (ignored by automatic top-level discovery).

## Quality Gates & Verification Workflow

All contributions and configuration changes MUST pass through the following quality gates:

1. **Formatting**: Run `just fmt` (or `nix fmt .`) to apply `alejandra` formatting to all `.nix` files and run all pre-commit formatting fixers.
2. **Linting & Diagnostics**: Run `just lint` (`deadnix` and `statix check`). Auto-fixable issues can be addressed with `just fix`.
3. **Flake Integrity & Checks**: Run `just check` (`nix flake check`) to validate syntax, evaluate derivations, and execute all pre-commit sandbox checks with 100% pass rate.
4. **Activation Testing**: Run `just test configuration="<host>"` (`nh os test .#<host>`) to activate and test configuration changes safely without setting a new bootloader entry.
5. **Deployment & Switch**: Run `just switch configuration="<host>"` (`nh os switch .#<host>`) or `just boot` to finalize system generation updates.

## Governance

This constitution defines the supreme operational and code standards for `my-nixos-configurations`. All feature additions, module refactoring, and AI-assisted workflows (Spec Kit) MUST adhere to these non-negotiable principles.

- **Amendments**: Amending this constitution requires modifying `.specify/memory/constitution.md`, explaining the rationale in the Sync Impact Report, and updating the version and date headers.
- **Versioning Policy**:
  - **MAJOR (X.0.0)**: Incompatible architectural shifts, principle deletions, or restructuring of core workflows.
  - **MINOR (0.X.0)**: Addition of new principles, new machine architectures, or expanded governance rules.
  - **PATCH (0.0.X)**: Wording clarifications, typo fixes, or documentation refinements.
- **Compliance**: All generated specifications (`/speckit-*`), plans, and tasks MUST verify alignment with these core principles during review and convergence.

**Version**: 2.0.0 | **Ratified**: 2026-08-12 | **Last Amended**: 2026-10-09
