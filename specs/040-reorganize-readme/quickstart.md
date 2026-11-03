# Quickstart Validation: Reorganize README for Progressive Disclosure and Clarity

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Spec**: [`specs/040-reorganize-readme/spec.md`](./spec.md)

---

## Prerequisites

- Local git clone checked out on branch `040-reorganize-readme`.
- Repository development shell activated (`direnv allow` or `nix develop`).

---

## Validation Scenario 1: Document Structure & File Layout

Verify that all target documentation files exist at their contracted paths:

```sh
test -f README.md
test -f docs/hosts/macbook.md
test -f docs/hosts/homelab.md
test -f docs/services/homelab-services.md
test -f docs/reference/shell-aliases.md
echo "All documentation files exist."
```

**Expected Outcome**: All 5 test assertions pass without error.

---

## Validation Scenario 2: Line Count Budget Verification (< 200 lines)

Verify that the root `README.md` has been reduced from 612 lines to under 200 lines:

```sh
LINES=$(wc -l < README.md)
echo "README.md line count: $LINES"
test "$LINES" -lt 200
```

**Expected Outcome**: `LINES` is strictly less than 200, achieving a >= 65% reduction in primary reading length.

---

## Validation Scenario 3: Relative Link Integrity

Verify that all relative links between `README.md` and `docs/` point to valid existing files:

```sh
# Verify links from README.md to docs/
grep -oE '\(docs/[^)]+\)' README.md | tr -d '()' | while read -r file; do
  test -f "$file" || echo "Broken link in README.md: $file"
done

# Verify breadcrumb links from docs/ back to README.md
find docs -name '*.md' | while read -r doc; do
  grep -q '\.\./\.\./README\.md' "$doc" || echo "Missing breadcrumb to README.md in $doc"
done
```

**Expected Outcome**: Zero broken link warnings emitted.

---

## Validation Scenario 4: Markdown Linting & Quality Gates

Run `markdownlint-cli2` across all repository Markdown files to verify formatting compliance:

**Bash**:

```bash
just lint-md
```

**Fish**:

```fish
just lint-md
```

**Expected Outcome**: `markdownlint-cli2` exits with code 0 and reports no lint or formatting errors.

---

## Validation Scenario 5: Dual-Shell (Bash & Fish) Command Parity

Verify that every operational code block requiring shell execution provides both **Bash** and **Fish** command blocks:

```sh
# Search for single-shell mentions where dual blocks are expected
find docs README.md -name '*.md' -exec grep -Hn "```bash" {} +
find docs README.md -name '*.md' -exec grep -Hn "```fish" {} +
```

**Expected Outcome**: For every `**Bash**` block in operational procedures, an equivalent `**Fish**` block is present.

---

## Validation Scenario 6: Flake Integrity & Pre-Commit Checks

Verify that documentation updates do not disrupt flake evaluation and hermetic sandbox checks:

```sh
just check
```

**Expected Outcome**: `nix flake check` evaluates cleanly with 100% pass rate.
