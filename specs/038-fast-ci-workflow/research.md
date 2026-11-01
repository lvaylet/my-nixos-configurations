# Technical Research: Fast CI Workflow (Remove Machine Builds)

**Feature**: `038-fast-ci-workflow`
**Date**: 2026-11-01
**Spec Reference**: `specs/038-fast-ci-workflow/spec.md`

## 1. Context & Problem Statement

The GitHub Actions CI pipeline (`.github/workflows/ci.yml`) currently operates as a two-stage pipeline:

1. **Stage 1 (`check`)**: Executes `nix flake check --print-build-logs` (runs all static checks, linters, pre-commit sandbox checks, and verifies flake output evaluation).
2. **Stage 2 (`build`)**: Runs a parallel matrix compiling full system toplevel closures and images for all defined machines:
   - `desktop-pc`: `.#nixosConfigurations.desktop-pc.config.system.build.toplevel`
   - `homelab`: `.#nixosConfigurations.homelab.config.system.build.toplevel`
   - `iso`: `.#nixosConfigurations.iso.config.system.build.isoImage`

### Identified Bottleneck

Compiling full NixOS system toplevel closures and generating an ISO image on hosted GitHub Actions `ubuntu-latest` runners takes between 15 and 40+ minutes per pull request or push. The runners must download gigabytes of store paths, evaluate complex closures, and occasionally compile heavy packages or derivations. This delays pull request reviews, burns through monthly GitHub Actions free tier quotas, and creates friction for rapid iterative development.

Meanwhile, this repository's deployment model requires operators to run `just test` or `just build` / `just switch` locally on or against target machines before activating changes. Remote CI's primary purpose is quality gating: ensuring syntactical validity, type-safe module evaluation, formatting, dead code avoidance, secret leakage protection, and flake integrity.

---

## 2. Technical Decisions & Analysis

### Decision 1: Remove Machine Build Matrix from `.github/workflows/ci.yml`

- **Decision**: Completely delete the `build` job matrix (`desktop-pc`, `homelab`, `iso`) from `.github/workflows/ci.yml`.
- **Rationale**:
  - Eliminates the 15–40+ minute execution bottleneck on GitHub Actions.
  - Reduces CI execution time down to the duration of `check` (typically 1–3 minutes).
  - Eliminates redundant downloading of system packages onto ephemeral remote runners.
  - CI remains a fast, agile quality gate rather than an overburdened build farm.
- **Alternatives Considered**:
  - *Keep builds only on `push` to `main` and disable on `pull_request`*: Rejected because building full machine closures on `main` still burns runner minutes without adding deployment value (deployment is performed locally or via `just switch` over SSH).
  - *Keep builds but add self-hosted runners*: Overkill for a personal homelab/desktop repository and adds maintenance overhead.
  - *Build only `homelab` or only `iso`*: Incomplete and still takes tens of minutes. Removing all machine build jobs directly satisfies the user requirement.

### Decision 2: Retain `nix flake check` as Comprehensive Remote Quality Gate

- **Decision**: Keep the `check` job running `nix flake check --print-build-logs` with `DeterminateSystems/nix-installer-action@v16` and `DeterminateSystems/magic-nix-cache-action@v9`.
- **Rationale**:
  - `nix flake check` evaluates every declared attribute and derivation output in `flake.nix`:
    - Evaluates all `nixosConfigurations` (`desktop-pc`, `homelab`, `iso`) and verifies that all NixOS module options, imports, assertions, and types are valid.
    - Runs `checks.<system>.pre-commit-check` inside a sandbox: runs `alejandra` formatting check, `statix` linting, `deadnix` dead code detection, `flake-checker`, and all secret leak detection hooks (`ripsecrets`, `trufflehog`, `detect-private-keys`).
    - Evaluates all `devShells` and formatters.
  - If any configuration introduces a syntax error, invalid option name, missing module, broken assertion, or secret, `nix flake check` catches it immediately in under 3 minutes.
- **Alternatives Considered**:
  - *Run only `just lint` without `nix flake check`*: Rejected because `nix flake check` also verifies full NixOS configuration evaluation across all machines.

### Decision 3: Update Living Documentation (`README.md`)

- **Decision**: Revise the `Continuous Integration` section in `README.md` to reflect the streamlined pipeline (single-stage quality gate running `nix flake check` + PR Markdown auto-fix).
- **Rationale**:
  - Enforces Constitution Principle VI (Living Documentation).
  - Clarifies for maintainers and reviewers that system toplevel compilation is handled locally during the standard verification workflow (`just test` / `just build`).

---

## 3. Comparison Matrix

| Aspect | Previous Architecture | Streamlined Architecture |
|---|---|---|
| **Pipeline Jobs** | `check` + `build` (`desktop-pc`, `homelab`, `iso`) | `check` only |
| **Typical Runtime** | 15 – 45 minutes | 1 – 3 minutes |
| **Runner Quota Usage** | High (~60–120 runner-min/run across matrix) | Minimal (~2–3 runner-min/run) |
| **Flake Evaluation Gate** | Yes (`nix flake check`) | Yes (`nix flake check`) |
| **Static & Secret Checks** | Yes (sandboxed pre-commit derivations) | Yes (sandboxed pre-commit derivations) |
| **Full Machine Compilation** | In CI (ephemeral, not deployed) | Local/Target prior to deploy (`just test` / `just build`) |
| **PR Feedback Loop** | Very Slow (blocking review) | Fast & Responsive |

---

## 4. Conclusion & Next Steps

All unknowns are resolved. The design is straightforward:

1. Simplify `.github/workflows/ci.yml` to remove the `build` job while keeping `check`.
2. Update `README.md` under `## Continuous Integration`.
3. Proceed to Phase 1: create `data-model.md`, interface contracts, and `quickstart.md`.
