# Quickstart Validation Guide: Harmonize Task Runner (`justfile`) Recipes

**Feature**: `028-harmonize-justfile-recipes`
**Date**: 2026-10-26
**Contract Reference**: [`contracts/justfile-cli.md`](./contracts/justfile-cli.md)

## Prerequisites

- Nix with Flakes enabled (`nix develop` or Devbox shell).
- `just` installed (`nix develop` provides `just` and `nh`).

## Validation Scenarios

### Scenario 1: Verify Unified Recipe List (`just --list`)

Run the default recipe and confirm that only the unified `(re)build` verbs (`boot`, `build`, `build-iso`, `install`, `switch`, `test`) are listed and all legacy host-suffixed recipes (`*-darwin`, `*-homelab`) are gone:

```sh
just --list
```

**Expected Outcome**:

- `(re)build` group displays `boot`, `build`, `build-iso`, `install`, `switch`, and `test`.
- Zero occurrences of `deploy-homelab`, `test-homelab`, `install-homelab`, `build-darwin`, `test-darwin`, or `switch-darwin`.

### Scenario 2: Dry-Run Command Evaluation (`just --dry-run`)

Validate how `just` interpolates parameters across local, remote, and Darwin invocations without modifying any live system:

```sh
# Default local auto-detection:
just --dry-run build
just --dry-run test
just --dry-run switch
just --dry-run boot

# Explicit Homelab target:
just --dry-run build homelab
just --dry-run test homelab
just --dry-run switch homelab
just --dry-run install 192.168.1.180

# Explicit macOS (Darwin) target:
just --dry-run build macbook-air-m4-15
just --dry-run test macbook-air-m4-15
just --dry-run switch macbook-air-m4-15
```

**Expected Outcome**:

- Every command parses and interpolates cleanly with exit code 0.

### Scenario 3: Cross-OS Guard Verification

Verify that running Darwin-only activation (`test`/`switch` for `macbook-air-m4-15`) on Linux or `boot`/`install` for `macbook-air-m4-15` fails fast with a helpful diagnostic message:

```sh
just boot macbook-air-m4-15
just test macbook-air-m4-15
```

**Expected Outcome**:

- Exits with non-zero status and prints a clear error message explaining the platform constraint.

### Scenario 4: Repository Quality Gates & Documentation Sync

Verify that `README.md` has zero stale recipe references and all repository checks pass:

```sh
just fmt
just lint
just check
```

**Expected Outcome**:

- `just fmt`, `just lint`, and `just check` all exit with code `0`.
