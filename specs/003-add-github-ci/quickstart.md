# Quickstart: CI Pipeline Validation Guide

**Feature Branch**: `003-add-github-ci` | **Date**: 2026-08-12 | **Spec**: [spec.md](spec.md)

This guide documents runnable validation scenarios to verify that the GitHub Actions CI pipeline functions correctly end-to-end.

---

## Prerequisites

- Local Nix installation or Devbox environment with `just` and `git` installed.
- Git repository with origin pointing to GitHub.
- GitHub Actions enabled on the target repository.

---

## Scenario 1: Local Pre-Push Verification (Shift-Left Quality)

Before pushing commits to GitHub, verify that local checks match the CI `check` stage exactly.

```bash
# 1. Run formatting check / fix
just fmt

# 2. Run static linters (deadnix, statix)
just lint

# 3. Run hermetic sandbox checks (pre-commit, secret detection, flake syntax)
just check
```

**Expected Outcome**:
All checks exit with code `0`. No dead code, unformatted Nix expressions, or secret leaks detected.

---

## Scenario 2: Local Closure Build Dry-Run

Verify that each system target compiles without errors before triggering cloud CI:

```bash
# Test desktop-pc closure build
nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel --no-link

# Test homelab closure build
nix build .#nixosConfigurations.homelab.config.system.build.toplevel --no-link

# Test ISO build
nix build .#nixosConfigurations.iso.config.system.build.isoImage --no-link
```

**Expected Outcome**:
All three derivations evaluate and build successfully without errors.

---

## Scenario 3: Pull Request Validation & Cloud Gating

1. Create a branch and push a commit to GitHub:

   ```bash
   git checkout -b test-ci-validation
   git commit --allow-empty -m "ci: test pull request validation"
   git push -u origin test-ci-validation
   ```

2. Open a Pull Request targeting `main`.
3. In the GitHub UI under **Checks**:
   - Verify `check` (Flake Check & Static Analysis) runs first.
   - Verify `build` matrix jobs (`desktop-pc`, `homelab`, `iso`) execute concurrently after `check` finishes.
   - Verify Magic Nix Cache logs show cache initialization and store path restoration.

**Expected Outcome**:
All jobs report a green checkmark (`✔`), status check passes, and PR is marked mergeable.

---

## Scenario 4: Intentional Failure & Quality Gate Verification

1. Introduce an intentional formatting violation or dead code in a temporary test branch.
2. Push the commit and inspect the GitHub Actions run.

**Expected Outcome**:

- `check` stage fails with actionable error messages highlighting the offending line.
- `build` matrix stage is skipped automatically (`needs: [check]`).
- The pull request is blocked from merging.

---

## Scenario 5: Manual Workflow Dispatch & Scheduled Run Verification

1. In GitHub web interface, navigate to **Actions** → **CI**.
2. Click **Run workflow** on branch `main`.
3. Verify that both `check` and all `build` matrix jobs complete successfully.

**Expected Outcome**:
Workflow completes successfully with full logs available for all matrix targets.
