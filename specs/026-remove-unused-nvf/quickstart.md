# Quickstart & Validation Guide: Remove Unused nvf Dependency

**Feature**: `026-remove-unused-nvf`
**Date**: 2026-10-26

## Prerequisites

- Nix with Flakes enabled (`nix --version`)
- Repository checked out on branch `026-remove-unused-nvf`

## Validation Steps

### 1. Verify `nvf` Removal from `flake.nix` and `flake.lock`

**Bash**:

```bash
# Confirm no references to nvf, mnw, or flake-compat_2 exist in flake.nix or flake.lock:
grep -E 'nvf|mnw|flake-compat_2' flake.nix flake.lock || echo "Clean: no unused nvf nodes found"
```

**Fish**:

```fish
# Confirm no references to nvf, mnw, or flake-compat_2 exist in flake.nix or flake.lock:
grep -E 'nvf|mnw|flake-compat_2' flake.nix flake.lock; or echo "Clean: no unused nvf nodes found"
```

**Expected Outcome**: Output prints `Clean: no unused nvf nodes found`.

### 2. Run Formatting and Static Analysis Quality Gates

**Bash**:

```bash
just fmt
just lint
```

**Fish**:

```fish
just fmt
just lint
```

**Expected Outcome**: `alejandra`, `deadnix`, and `statix` complete with zero warnings or errors.

### 3. Run Full Flake Evaluation & Pre-Commit Checks

**Bash**:

```bash
just check
```

**Fish**:

```fish
just check
```

**Expected Outcome**: `nix flake check` evaluates all `nixosConfigurations` (`desktop-pc`, `homelab`, `iso`), `darwinConfigurations` (`macbook-air-m4-15`), `devShells`, and `pre-commit-check` with exit code 0.
