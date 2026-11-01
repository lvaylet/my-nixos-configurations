# Feature Specification: Fast CI Workflow (Remove Machine Builds)

**Feature Branch**: `038-fast-ci-workflow`

**Created**: 2026-11-01

**Status**: Draft

**Input**: User description: "Les GitHub Actions prennent trop de temps. Supprime les phases de Build pour chaque machine. Conserve les vérifications statiques et le Flake Check."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fast Continuous Integration Feedback on Pull Requests (Priority: P1)

As a repository contributor or maintainer opening or updating a Pull Request, I want the automated CI pipeline to execute rapidly without building full system closures (`desktop-pc`, `homelab`, `iso`), so that I receive validation feedback on flake integrity, code formatting, and static analysis within a few minutes rather than waiting tens of minutes for redundant full-system image compilations.

**Why this priority**: System builds on GitHub Actions runners consume excessive execution time (15–40+ minutes) and runner minutes. Suppressing the matrix build jobs while preserving static checks and flake checks delivers immediate value by drastically accelerating the review and merge loop.

**Independent Test**: Push a commit or open a Pull Request and verify that the `CI` workflow completes cleanly in under 3 minutes, executing only the flake check and static analysis job without scheduling or running system build jobs.

**Acceptance Scenarios**:

1. **Given** a Pull Request targeting `main`, **When** the GitHub Actions `CI` workflow triggers, **Then** only the flake check and static analysis job executes and succeeds without running host build matrix jobs (`desktop-pc`, `homelab`, `iso`).
2. **Given** a commit pushed directly to `main`, a scheduled run, or a manual `workflow_dispatch` trigger, **When** the workflow runs, **Then** it validates the repository via `nix flake check` without compiling machine closures.

---

### User Story 2 - Preserved Flake Evaluation and Security Validation (Priority: P2)

As a project maintainer, I want all flake outputs, syntax, module evaluations, pre-commit hooks (formatting with `alejandra`, dead code detection with `deadnix`, linting with `statix`), and secret scanning filters (`ripsecrets`, `trufflehog`, `detect-private-keys`) to remain strictly enforced as the CI quality gate, so that code quality and security are never compromised by the speed optimization.

**Why this priority**: Fast feedback is only beneficial if quality standards remain intact. `nix flake check` hermetically evaluates the entire flake schema and all system configurations, catching syntax errors, undefined attributes, and module misconfigurations before merge.

**Independent Test**: Introduce a deliberate linting, formatting, or flake evaluation defect and verify that the `CI` workflow promptly fails at the check stage, preventing invalid code from passing the quality gate.

**Acceptance Scenarios**:

1. **Given** a Pull Request with valid code, **When** `nix flake check` executes in CI, **Then** all evaluation checks, formatters, and pre-commit sandbox derivations succeed.
2. **Given** a Pull Request introducing unformatted code, dead bindings, or invalid Nix syntax, **When** `nix flake check` executes in CI, **Then** the workflow fails with explicit diagnostics and blocks merge.

---

### User Story 3 - Synchronized Living Documentation of the CI Architecture (Priority: P3)

As a contributor or external reviewer reading the project documentation, I want `README.md` to accurately describe the streamlined CI workflow, so that there is no discrepancy between documented pipeline stages and the actual GitHub Actions execution graph.

**Why this priority**: Aligns with Constitution Principle VI (Living Documentation). Stale documentation describing deprecated matrix build stages causes confusion and diminishes trust in project documentation.

**Independent Test**: Review `README.md` under the *Continuous Integration* section to confirm it documents the single-stage quality gate and explains that full host builds are performed locally prior to deployment.

**Acceptance Scenarios**:

1. **Given** the repository documentation in `README.md`, **When** inspecting the *Continuous Integration* section, **Then** it describes the streamlined quality gate running `nix flake check` and omits obsolete references to multi-machine matrix builds.

---

### Edge Cases

- **Build-time compilation failures undetected by evaluation**: Some package compilation or derivation build failures (e.g. upstream patch failures or build script errors) might only surface when compiling the package store path. In this workflow, full machine builds are validated locally via `just build` or `just test` before deployment, maintaining overall stability while keeping remote CI fast.
- **Workflow dispatch with optional parameters**: When triggered manually via `workflow_dispatch`, the workflow executes the same streamlined validation suite.
- **Concurrent runs on updated branches**: Pushing new commits to an open PR cancels in-progress runs via `cancel-in-progress: true`, avoiding redundant runner usage.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The GitHub Actions CI workflow MUST NOT execute build jobs for individual machine targets (`desktop-pc`, `homelab`, `iso`).
- **FR-002**: The GitHub Actions CI workflow MUST execute the flake check job running `nix flake check --print-build-logs` on pull requests, pushes to `main`, scheduled runs, and manual dispatches.
- **FR-003**: The CI workflow MUST retain hermetic Nix installation (`DeterminateSystems/nix-installer-action`) and binary store caching (`DeterminateSystems/magic-nix-cache-action`) to ensure fast and reproducible runs.
- **FR-004**: The CI workflow MUST maintain concurrency control (`cancel-in-progress: true`) to avoid wasted CI runner minutes on outdated commits.
- **FR-005**: The repository documentation (`README.md`) MUST accurately reflect the streamlined CI architecture and describe the validation stages without obsolete build matrix references.

### Key Entities

- **CI Workflow (`.github/workflows/ci.yml`)**: GitHub Actions workflow governing automated quality checks and validation gates across branches and pull requests.
- **Flake Check Derivations (`nix flake check`)**: Hermetic sandbox checks that evaluate all host configurations, devShells, formatters, and git pre-commit hooks.
- **Machine Build Matrix**: Deprecated workflow stage that built complete top-level derivations and ISO images on remote CI runners.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: CI workflow duration on GitHub Actions is reduced by at least 75% (completing in under 3 minutes compared to 15–40+ minutes for full system builds).
- **SC-002**: 100% of pull requests and pushes to `main` continue to be gated by flake evaluation, pre-commit hooks, and static analysis with zero regression in quality checks.
- **SC-003**: The CI workflow definition contains exactly zero machine build matrix jobs.
- **SC-004**: Repository documentation in `README.md` is 100% synchronized with the streamlined CI pipeline structure.

## Assumptions

- Machine closures and ISO images will continue to be built and tested locally or on target hosts prior to deployment (`just build`, `just test`, `just switch`).
- `nix flake check` provides sufficient verification of Nix expression syntax, module typing, option definitions, and configuration evaluations across all declared hosts.
- The dedicated Markdown auto-fix workflow (`.github/workflows/markdownlint-fix.yml`) remains unchanged and operational.
