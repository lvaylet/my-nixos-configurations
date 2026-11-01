# Quickstart & Verification Guide: Fast CI Workflow (Remove Machine Builds)

**Feature Branch**: `038-fast-ci-workflow`
**Date**: 2026-11-01
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

This guide documents the procedures for verifying the streamlined CI workflow locally and validating that GitHub Actions runs fast flake checks without scheduling machine build jobs.

---

## 1. Prerequisites

- Working copy on branch `038-fast-ci-workflow`.
- Nix with flakes enabled.
- `just` task runner.
- (Optional) GitHub CLI (`gh`) for inspecting workflow runs.

---

## 2. Verification Scenarios

### Scenario 1: Validate Workflow File Syntax & Job Structure

Verify that `.github/workflows/ci.yml` contains only the `check` job and no `build` job.

**Bash & Fish:**

```shell
# Inspect defined jobs in ci.yml:
grep -E '^[[:space:]]{2}[a-zA-Z0-9_-]+:' .github/workflows/ci.yml
```

**Expected Output:**

```text
  check:
```

(The string `build:` MUST NOT appear as a job under `jobs:`).

### Scenario 2: Verify Flake Check Runs Cleanly Locally

Simulate the exact command executed by the CI check job to ensure hermetic parity:

**Bash & Fish:**

```shell
# Run flake check matching CI step:
nix flake check --print-build-logs
```

**Expected Output:**

- All derivations and checks (including `pre-commit-check`, `devShells`, `packages`, and `nixosConfigurations`) evaluate and succeed with exit code `0`.

### Scenario 3: Verify Pre-Commit Formatting & Linting Quality Gates

Run repository linting and formatting recipes to ensure all quality gates pass:

**Bash & Fish:**

```shell
# Run formatting check:
just fmt

# Run static analysis and dead code detection:
just lint

# Run markdownlint checks:
just lint-md

# Run full flake check:
just check
```

**Expected Output:**

- All checks pass cleanly with exit code `0` and 0 errors.

### Scenario 4: Remote CI Run Validation (Post-Push)

After pushing the feature branch or opening a Pull Request:

**Bash & Fish:**

```shell
# Watch the CI workflow run in real time:
gh run watch

# Or list recent runs:
gh run list --workflow=ci.yml --limit=3
```

**Expected Behavior:**

- Only one job (`Flake Check & Static Analysis`) is scheduled and executed.
- Zero machine build jobs (`desktop-pc`, `homelab`, `iso`) are queued or run.
- Total runtime is under 3 minutes.
