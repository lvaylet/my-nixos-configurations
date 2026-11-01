# Implementation Plan: Fast CI Workflow (Remove Machine Builds)

**Branch**: `038-fast-ci-workflow` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/038-fast-ci-workflow/spec.md`

## Summary

Streamline the continuous integration pipeline on GitHub Actions by removing the multi-machine build matrix jobs (`desktop-pc`, `homelab`, `iso`) from `.github/workflows/ci.yml`. Retain the comprehensive `check` job running `nix flake check --print-build-logs` (which validates flake syntax, NixOS configuration evaluation, formatters, and static security/linting pre-commit hooks) to deliver fast quality feedback (under 3 minutes) while saving runner minutes. Synchronize `README.md` to accurately document the streamlined CI architecture.

Technical approach:

1. Edit `.github/workflows/ci.yml` to remove the `build` matrix job while preserving the `check` job, triggers (`pull_request`, `push`, `schedule`, `workflow_dispatch`), and concurrency rules (`cancel-in-progress: true`).
2. Update `README.md` under `## Continuous Integration` to reflect the single-stage quality gate and document that full machine compilation is handled locally before deployment.
3. Validate locally with `just fmt`, `just lint`, `just lint-md`, and `just check`.

---

## Technical Context

**Language/Version**: GitHub Actions YAML, Markdown

**Primary Dependencies**:

- GitHub Actions (`actions/checkout@v4`)
- Determinate Systems Nix tools (`DeterminateSystems/nix-installer-action@v16`, `DeterminateSystems/magic-nix-cache-action@v9`)
- Nix (`nix flake check`)
- `just` task runner

**Storage**: N/A (CI workflow configuration)

**Testing**:

- CI workflow structure verification (`grep -E '^[[:space:]]{2}[a-zA-Z0-9_-]+:' .github/workflows/ci.yml`)
- Flake checks: `nix flake check --print-build-logs` / `just check`
- Markdown linting: `just lint-md` (`markdownlint-cli2`)
- Code formatting & linting: `just fmt`, `just lint`

**Target Platform**: GitHub Actions runner (`ubuntu-latest`)

**Project Type**: CI/CD Automation & Repository Quality Gates

**Performance Goals**:

- Reduce CI workflow duration from 15–40+ minutes down to 1–3 minutes.
- Reduce GitHub Actions runner consumption by ~90% per pull request.

**Constraints**:

- Strict Constitution compliance: flake integrity, pre-commit checks (`alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`), and NixOS configuration evaluation MUST remain 100% enforced in CI.
- Dual-shell documentation parity: all operational instructions in `README.md` must maintain explicit Bash and Fish parity.
- Zero secrets leakage.

**Scale/Scope**:

- 1 modified CI workflow file: `.github/workflows/ci.yml`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | CI workflow executes `nix flake check` against declarative, hermetic flake outputs without mutating repository state. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | Flake evaluation in `nix flake check` continuously asserts that dendritic modularity rules and host configurations remain valid. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | The `check` job runs `nix flake check` which executes all pre-commit hooks in isolated sandbox derivations (`alejandra`, `deadnix`, `statix`, `ripsecrets`, `trufflehog`). |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials in repo; secret scanners enforced | **PASS** | Secret detection hooks remain active in `nix flake check` on every PR and commit. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | Local verification workflow (`just test` / `just build` / `just switch`) remains unchanged and is explicitly documented. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` updated in the same branch to accurately describe the single-stage quality gate with dual-shell command examples. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | Tracked under dedicated branch `038-fast-ci-workflow`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/038-fast-ci-workflow/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 output: analysis of build removal vs check coverage
├── data-model.md        # Phase 1 output: workflow schema, job definitions, and lifecycle
├── quickstart.md        # Phase 1 output: verification commands and test scenarios
├── contracts/           # Phase 1 output: workflow invariants and guarantees
│   └── ci-workflow-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
.github/
└── workflows/
    ├── ci.yml              # Updated: removes build matrix job, preserves check job
    └── markdownlint-fix.yml # Unchanged: PR Markdown auto-fix workflow
README.md                   # Updated: documents streamlined CI pipeline
```

**Structure Decision**: Standard GitHub Actions workflow layout. No new directories required; targets `.github/workflows/ci.yml` and `README.md`.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitutional violations. Complexity tracking not required.
