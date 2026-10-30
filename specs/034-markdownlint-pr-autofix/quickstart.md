# Quickstart Validation Guide: Markdownlint Availability & Pull Request Auto-Fix

**Feature**: Markdownlint Availability & Pull Request Auto-Fix
**Branch**: `034-markdownlint-pr-autofix`
**Date**: 2026-10-30
**Spec**: [`specs/034-markdownlint-pr-autofix/spec.md`](./spec.md)
**Contracts**: [`contracts/`](./contracts/) | **Data Model**: [`data-model.md`](./data-model.md)

---

## Prerequisites

- Nix with flakes enabled (`nix-command flakes`)
- Working repository checkout on branch `034-markdownlint-pr-autofix`

---

## Scenario 1: Verify System-Wide Package Availability

### Objective

Ensure `markdownlint-cli2` is packaged and available in both the NixOS and Darwin base module definitions as well as the repository development shell.

### Commands

**In devshell or with package in path:**

```bash
# Bash
nix develop -c markdownlint-cli2 --version
```

```fish
# Fish
nix develop -c markdownlint-cli2 --version
```

### Expected Outcome

`markdownlint-cli2` executes and prints version information (e.g. `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)`) with zero errors.

---

## Scenario 2: Validate Declarative Exemption of `.agents/` and `.opencode/`

### Objective

Prove that running `markdownlint-cli2` processes repository Markdown files while strictly ignoring any Markdown documents located inside `.agents/` and `.opencode/`.

### Commands

```bash
# Bash
markdownlint-cli2
```

```fish
# Fish
markdownlint-cli2
```

### Expected Outcome

- The command output summary indicates files were found and linted.
- Notice the discovery output displays `!.agents/**` and `!.opencode/**` as excluded globs.
- Zero issues or file reads are reported for `.agents/skills/*/*.md` and `.opencode/commands/*.md`.

---

## Scenario 3: Verify Automated Local Auto-Fix (`--fix`)

### Objective

Prove that running `just fix-md` or `markdownlint-cli2 --fix` automatically corrects fixable style issues (e.g. trailing whitespace) in general documentation files without touching `.agents/` or `.opencode/`.

### Commands

```bash
# Bash
# 1. Intentionally create a style defect in a test file
printf "# Test Title   \n\nSome text with trailing spaces   \n" > /tmp/opencode/quickstart-test.md

# 2. Run autofix via markdownlint-cli2
markdownlint-cli2 --fix /tmp/opencode/quickstart-test.md

# 3. Verify trailing spaces were eliminated
cat -A /tmp/opencode/quickstart-test.md
rm -f /tmp/opencode/quickstart-test.md
```

### Expected Outcome

- The trailing whitespace is stripped cleanly.
- If run against test files in `.agents/` or `.opencode/`, the files remain untouched.

---

## Scenario 4: Validate GitHub Actions Workflow Syntax

### Objective

Ensure that the `.github/workflows/markdownlint-fix.yml` workflow file is valid and correctly formatted.

### Commands

```bash
# Bash / Fish
git check-ref-format --branch 034-markdownlint-pr-autofix
nix flake check
```

### Expected Outcome

The flake check passes with zero errors and pre-commit hooks succeed cleanly.
