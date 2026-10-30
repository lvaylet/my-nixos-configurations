# Contract: Operational Task Runner Recipes (`justfile`)

**File**: `justfile`
**Purpose**: Expose standardized operational recipes for checking, linting, and fixing Markdown documentation locally.

---

## 1. Recipe Signatures & Descriptions

```just
# lint Markdown files with markdownlint-cli2 (excluding .agents and .opencode)
[group('dev-utils')]
lint-md:
  markdownlint-cli2

# fix Markdown files with markdownlint-cli2 (excluding .agents and .opencode)
[group('dev-utils')]
fix-md:
  markdownlint-cli2 --fix
```

---

## 2. Integration into Existing Composite Recipes

To maintain a streamlined developer experience, `lint-md` and `fix-md` integrate with the general `lint` and `fix` recipes:

```just
# run linters (Nix + Markdown)
[group('dev-utils')]
lint:
  deadnix
  statix check
  markdownlint-cli2

# fix warnings reported by linters (Nix + Markdown)
[group('dev-utils')]
fix:
  deadnix --edit
  statix fix
  markdownlint-cli2 --fix
```

---

## 3. Shell Parity Invariants (Principle VI)

All command examples in `README.md` MUST provide dual syntax for **Bash** and **Fish**:

```markdown
<!-- Bash -->
just fix-md
# or
markdownlint-cli2 --fix

<!-- Fish -->
just fix-md
# or
markdownlint-cli2 --fix
```
