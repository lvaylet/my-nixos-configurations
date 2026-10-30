# Phase 0 Research: Markdownlint Availability & Pull Request Auto-Fix

**Feature**: Markdownlint Availability & Pull Request Auto-Fix
**Branch**: `034-markdownlint-pr-autofix`
**Date**: 2026-10-30
**Spec**: [`specs/034-markdownlint-pr-autofix/spec.md`](./spec.md)

---

## Research Topics & Decisions

### Decision 1: System-Wide Configuration & Package Placement

- **Context**: The feature requires adding `markdownlint-cli2` to "all configurations" across the repository. The repository manages multi-platform target configurations: NixOS hosts (`desktop-pc`, `homelab`, `iso`), macOS Darwin host (`macbook-air-m4-15`), and local developer environments (`nix develop`).
- **Decision**:
  1. Add `markdownlint-cli2` to `modules/core/base.nix` in `flake.modules.core.base.nixos.environment.systemPackages` (automatically inherited by `desktop-pc`, `homelab`, and `iso`).
  2. Add `markdownlint-cli2` to `modules/core/base.nix` in `flake.modules.core.base.darwin.environment.systemPackages` (inherited by `macbook-air-m4-15`).
  3. Add `markdownlint-cli2` to `modules/core/devshell.nix` in `devShells.default.buildInputs` for immediate availability inside `nix develop`.
  4. Expose operational recipes in `justfile` (`just lint-md` and `just fix-md`, and integrate into `just lint` and `just fix`).
- **Rationale**:
  - `modules/core/base.nix` is the shared foundation module imported by every host in the flake. Colocating `markdownlint-cli2` alongside developer tools (`alejandra`, `statix`, `deadnix`) guarantees universal availability across all hosts without per-host code duplication.
  - Adding to `modules/core/devshell.nix` ensures contributors who have not yet switched their system generation can immediately use the linter in an ad-hoc subshell.
- **Alternatives Considered**:
  - Adding to `modules/desktop/editors.nix`: Rejected because headless servers like `homelab` and minimal installations like `iso` do not import desktop modules, violating the "all configurations" requirement.
  - Adding individually to each host under `modules/hosts/`: Rejected because it violates Principle II (Dendritic Modularity & DRY composition).

---

### Decision 2: Rule Configuration & `.agents` Exclusion Mechanism

- **Context**: The auto-fix and linting must cover all Markdown files in the repository while strictly exempting files in the `.agents` subfolder (`.agents/**`).
- **Decision**: Define a declarative top-level `.markdownlint-cli2.yaml` file in the repository root:

  ```yaml
  globs:
    - "**/*.md"
  ignores:
    - ".agents/**"
  ```

- **Rationale**:
  - `markdownlint-cli2` automatically detects `.markdownlint-cli2.yaml` at the root of the project.
  - Specifying `ignores: [".agents/**"]` in the configuration file guarantees that any invocation (`markdownlint-cli2 --fix`, `just fix`, editor extensions, CI workflows) consistently respects the exclusion without requiring CLI glob quoting workarounds across different shells.
  - Validated by empirical testing: running `markdownlint-cli2 --fix` with this configuration properly processes root and subfolder Markdown files while ignoring `.agents/**`.
- **Alternatives Considered**:
  - Passing negated CLI arguments like `'!.agents/**'` or `'#.agents/**'`: Fragile because POSIX shells (Bash, Zsh, Fish) treat exclamation marks and hash marks differently, leading to glob expansion errors or unquoted parameter splits.
  - Using a custom shell script with `find` or `fd`: Unnecessary indirection when `markdownlint-cli2` natively supports `ignores` in its configuration schema.

---

### Decision 3: Pull Request Auto-Correction Workflow Design

- **Context**: Automated correction with `markdownlint-cli2 --fix` must run on each Pull Request, committing and pushing changes back to the PR branch when fixes are made.
- **Decision**: Implement a dedicated GitHub Actions workflow `.github/workflows/markdownlint-fix.yml`:
  - **Trigger**: `pull_request` (events: `opened`, `synchronize`, `reopened`) targeting `main`.
  - **Concurrency**: `cancel-in-progress: true` keyed by `github.workflow` and `github.head_ref`.
  - **Permissions**: `contents: write` to allow pushing auto-formatting commits back to the PR head branch.
  - **Runner Steps**:
    1. Checkout repository with `actions/checkout@v4` targeting `ref: ${{ github.head_ref }}` and full repository permissions.
    2. Install Nix using `DeterminateSystems/nix-installer-action@v16` and enable caching with `magic-nix-cache-action@v9`.
    3. Run `markdownlint-cli2 --fix` via hermetic `nix shell nixpkgs#markdownlint-cli2 -c markdownlint-cli2 --fix`.
    4. Commit and push modifications using `stefanzweifel/git-auto-commit-action@v5` with commit message `style(markdown): auto-format markdown files with markdownlint-cli2`.
- **Rationale**:
  - Separating the auto-fix workflow from `ci.yml` prevents concurrency deadlocks: when the auto-fix workflow pushes an updated commit to the PR branch, GitHub Actions automatically restarts the main validation pipeline (`ci.yml`) on the freshly formatted commit.
  - If `ci.yml` itself attempted to push commits mid-flight while evaluating `nix flake check` or building system closures, the push would invalidate the running job and trigger race conditions.
  - Running via `nix shell nixpkgs#markdownlint-cli2` ensures the exact same version of the linter is used in CI as in the local developer environment, maintaining hermetic parity.
- **Alternatives Considered**:
  - Relying solely on pre-commit hooks: Does not solve PR auto-correction when contributors submit PRs via web interfaces or without local hooks installed.
  - Creating a separate GitHub PR comment with diff patch: Much worse contributor ergonomics than automatic commit-and-push.

---

### Decision 4: Constitutional Compliance & Living Documentation

- **Context**: Principle VI requires that `README.md` must be updated within the branch to document all added tools, with dual **Bash** and **Fish** operational commands.
- **Decision**: Update `README.md` to document the new `markdownlint-cli2` tooling, explain the automated PR formatting workflow, and list operational recipes in both Bash and Fish:
  - Bash: `just lint-md` / `just fix-md` or `nix shell nixpkgs#markdownlint-cli2 -c markdownlint-cli2 --fix`
  - Fish: `just lint-md` / `just fix-md` or `nix shell nixpkgs#markdownlint-cli2 -c markdownlint-cli2 --fix`
- **Rationale**: Guarantees zero documentation drift and ensures complete compliance with Principle VI.
