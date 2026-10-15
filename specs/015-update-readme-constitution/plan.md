# Implementation Plan: Update README for Constitution Compliance and Dual-Shell Parity

**Branch**: `015-update-readme-constitution` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/015-update-readme-constitution/spec.md`

## Summary

Update `README.md` to achieve 100% compliance with `.specify/memory/constitution.md` (v2.1.0). Specifically:
1. **Dual-Shell Command Parity (Principle VI)**: Provide explicit **Bash** and **Fish** command variants whenever instructions use shell-specific syntax (`export TARGET_IP=...` and `${TARGET_IP}` vs `set -gx TARGET_IP ...` and `$TARGET_IP` for homelab provisioning/SSH/deployment; `sudo tee ... << 'EOF'` heredocs vs single-quoted `printf '%s\n' ... | sudo tee ...` for `cloudflare.env` and `waha.env` secret provisioning).
2. **Host Shell Duality & Complete Alias Documentation**: Explain how **Fish** (primary user `laurent`'s default login shell with native `complete -w` autocompletions and Home Manager desktop aliases/functions in `modules/desktop/shell.nix`) and **Bash** (`root` login shell, installer ISO, and bootstrap hosts) coexist while sharing system-wide `environment.shellAliases` (`modules/core/base.nix`), and complete the Git aliases table (`gcan!`, `grba`, `grbc`, `gstd`, `gclean`).
3. **Architectural & Governance Alignment (Principles II, III, V, VI, VII)**: Update the `modules/desktop/` summary in the Architecture tree (`Niri Wayland session, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU` instead of `NNN desktop session`) and document the 7-stage Constitutional Quality Gates & Verification Workflow (including dedicated branch + Pull Request isolation and `just test` before `just switch`).

---

## Technical Context

**Language/Version**: GitHub-Flavored Markdown (`README.md`), GNU Bash (`bash`), Friendly Interactive Shell (`fish`), Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `modules/core/base.nix` (declares `users.users.${vars.userName}.shell = pkgs.fish`, `environment.shellAliases`, and `programs.fish` completions)
- `modules/desktop/shell.nix` (declares Home Manager `programs.fish` aliases/functions and `programs.starship`)
- `.specify/memory/constitution.md` (v2.1.0 project governance and principles)
- `justfile` (operational recipes for building, testing, switching, formatting, linting, and checking)

**Storage**: N/A (repository root documentation `README.md`).

**Testing**:

- Shell syntax validation: `bash -n` for Bash snippets and `fish --no-execute` (`fish -n`) for Fish snippets.
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Hermetic sandbox & secret/hygiene checks: `just check` (`nix flake check`, running `ripsecrets`, `trufflehog`, `detect-private-keys`, `trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflicts`).

**Target Platform**: All repository targets (`desktop-pc`, `homelab`, `iso`) and cross-platform contributor workstations (Linux, macOS, WSL2).

**Project Type**: Declarative NixOS & Home Manager multi-host configuration repository documentation.

**Performance Goals**: N/A (documentation artifact; zero runtime overhead).

**Constraints**:

- Strict adherence to Constitution Principles I–VII (v2.1.0).
- Zero plaintext secrets or tokens (placeholder strings `<your-cloudflare-api-token>`, `<your-waha-api-key>`, etc. must pass `ripsecrets` and `trufflehog`).
- Zero unsupported POSIX heredocs (`<<`) in Fish snippets.
- Single-quoted strings used in Fish secret provisioning snippets to prevent `$` variable expansion.

**Scale/Scope**:

- 1 primary documentation file updated: `README.md`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Documentation accurately reflects declarative NixOS/Home Manager modules and explicitly documents persistent runtime secret files under `/persistent/var/lib/`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Architecture section in `README.md` is updated to match the exact `core/`, `desktop/`, `services/`, and `hosts/` domain layout. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox, file hygiene | **PASS** | Validated via `just fmt`, `just lint`, and `just check` (enforcing trailing whitespace and EOF newline hygiene on `README.md`). |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | All provisioning examples use safe `<placeholder>` tokens, enforce `0600` file modes, and pass `ripsecrets`/`trufflehog` checks. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> `just test` before `just switch` | **PASS** | Explicitly documented in the new Quality Gates & Verification Workflow section of `README.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronization; dual Bash/Fish command variants where syntax differs | **PASS** | Primary objective of this feature: adds explicit `Bash` and `Fish` variants for all shell-specific commands and documents the Bash/Fish architecture. |
| **VII. Dedicated Branch & Pull Request Workflow** | Dedicated branch and associated Pull Request targeting `main` | **PASS** | Documented in `README.md` Quality Gates and enforced for delivering this feature via branch `015-update-readme-constitution`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/015-update-readme-constitution/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Dual-shell transformation matrix & alias model (Phase 1 output)
├── quickstart.md        # Runnable validation scenarios (Phase 1 output)
├── contracts/           # Documentation compliance contract (Phase 1 output)
│   └── readme-compliance-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
README.md                # Updated root living documentation with dual Bash/Fish parity
modules/
├── core/
│   └── base.nix         # Reference source for system-wide aliases & Fish completions
└── desktop/
    └── shell.nix        # Reference source for desktop Fish aliases, functions & Starship
```

**Structure Decision**:
Updates `README.md` in place at the repository root while referencing `modules/core/base.nix`, `modules/desktop/shell.nix`, `justfile`, and `.specify/memory/constitution.md` as authoritative sources of truth.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All changes strictly comply with Constitution Principles I–VII | N/A |
