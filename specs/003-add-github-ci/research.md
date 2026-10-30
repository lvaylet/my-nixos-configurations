# Research & Architectural Decisions: Modern Continuous Integration Pipeline

**Feature Branch**: `003-add-github-ci` | **Date**: 2026-08-12 | **Spec**: [spec.md](spec.md)

## Decision 1: CI Platform & Workflow Architecture

### Decision

Implement continuous integration via a unified, declarative GitHub Actions workflow located at `.github/workflows/ci.yml` structured as a two-stage gated pipeline (`check` stage followed by parallel `build` matrix stage).

### Rationale

- **Two-Stage Gatekeeper**: Fast static analysis, flake syntax checking, code formatting verification, and secret scanning execute first in the `check` job (runtime <1-2 minutes). If linting or formatting fails, downstream compute-heavy system closure builds are skipped, preventing wasted runner minutes.
- **Matrix Parallelism**: The `build` job utilizes GitHub Actions matrix execution (`desktop-pc`, `homelab`, `iso`) across independent runner VMs. This isolates failures to specific targets, prevents runner disk exhaustion, and allows parallel execution.
- **Native Event Triggers**: Supports `pull_request` against `main`, direct `push` to `main`, scheduled weekly health verification (`schedule: cron '0 4 * * 1'`), and manual ad-hoc execution (`workflow_dispatch`).
- **Concurrency Control**: Applies `concurrency: group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true` to instantly terminate obsolete in-flight CI runs when newer commits are pushed to a PR.

### Alternatives Considered

- *Single monolithic job*: Running checks and all machine builds sequentially in one job would take 15-30 minutes and mask target-specific failure logs.
- *Separate workflow files for check and build*: Having `lint.yml` and `build.yml` would duplicate checkout/installer setup steps and make dependency gating between check and build complex.

---

## Decision 2: Nix Installation & Binary Store Caching

### Decision

Adopt **Determinate Systems Nix Installer** (`determinate-nix-installer-action`) coupled with **Magic Nix Cache** (`magic-nix-cache-action`).

### Rationale

- **Zero Configuration**: Magic Nix Cache runs as a local background daemon on the GitHub runner that automatically intercepts `/nix/store` writes and persists cache archives directly into GitHub Actions cache storage.
- **No External Secrets**: Unlike Cachix or external S3 buckets, Magic Nix Cache requires no API keys, auth tokens, or third-party service accounts, making it 100% secure for open-source public repositories and pull requests from forks.
- **Fast Startup & Flakes Support**: Determinate Systems Nix Installer configures Nix flakes and sensible defaults (`extra-nix-config: "accept-flake-config = true"`) out-of-the-box in seconds.
- **Performance**: Cuts downstream matrix build times by 60–80% for warm runs.

### Alternatives Considered

- *`nix-community/install-nix-action` + `actions/cache`*: Requires manual tarring/caching of `/nix/store`, which frequently encounters permissions issues, slow restore times, and cache eviction boundaries.
- *Cachix*: Requires configuring repository secrets (`CACHIX_AUTH_TOKEN`), which are not accessible on PRs originating from external forks due to GitHub security restrictions.

---

## Decision 3: Build Matrix Targets & Commands

### Decision

Define a build matrix spanning the three top-level system configurations declared in `flake.nix`:

1. `desktop-pc` → `nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel --print-build-logs`
2. `homelab` → `nix build .#nixosConfigurations.homelab.config.system.build.toplevel --print-build-logs`
3. `iso` → `nix build .#nixosConfigurations.iso.config.system.build.isoImage --print-build-logs`

### Rationale

- Matches the declarations in `flake.nix` (`nixosConfigurations.desktop-pc`, `nixosConfigurations.homelab`, `nixosConfigurations.iso`).
- Building `.toplevel` validates the complete system closure (kernel, systemd units, package derivations, Home Manager modules, activation scripts) without requiring root privileges or physical target hardware.
- Building `.isoImage` validates the bootable live CD derivation and its installer modules.
- `--print-build-logs` ensures that any compilation errors or derivation failures are immediately visible in the GitHub Actions runner UI.

### Alternatives Considered

- *Building with `just build`*: `just build` contains interactive environment detection logic suited for local workstations. In CI, invoking standard, explicit `nix build` expressions guarantees deterministic evaluation and clean log capture.

---

## Decision 4: Security Posture & Least-Privilege Permissions

### Decision

Configure explicit, top-level read-only workflow permissions (`permissions: contents: read`) and disable automated pull request creation in CI.

### Rationale

- Adheres to Principle IV (Zero-Secrets Leakage) and GitHub security best practices.
- PRs from public forks execute safely with read-only permissions and cannot modify repository settings or access deployment keys.
- Secret scanning (`trufflehog`, `ripsecrets`, `detect-private-keys`) runs hermetically inside `nix flake check` sandbox checks on every commit.

### Alternatives Considered

- *`permissions: write-all`*: Violates least privilege and introduces security vulnerabilities for untrusted fork contributions.
