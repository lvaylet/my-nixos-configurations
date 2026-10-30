# Phase 1 Data Model: Markdownlint Availability & Pull Request Auto-Fix

**Feature**: Markdownlint Availability & Pull Request Auto-Fix
**Branch**: `034-markdownlint-pr-autofix`
**Date**: 2026-10-30
**Spec**: [`specs/034-markdownlint-pr-autofix/spec.md`](./spec.md)

---

## Entities

### 1. MarkdownDocument

Represents any Markdown file residing within the repository filesystem.

| Field | Type | Description | Validation Rules |
| --- | --- | --- | --- |
| `path` | `string` | Relative path from repository root | Must end with `.md` or `.markdown` |
| `scope` | `enum` | Domain classification | One of `documentation`, `specification`, `agent-instruction`, `vendor` |
| `isExempt` | `boolean` | Whether automated linting and formatting is disabled | `true` if path begins with `.agents/` or `.opencode/`, `false` otherwise |
| `formattingState` | `enum` | Conformance with markdownlint rules | One of `clean`, `auto-fixable`, `syntax-error` |

#### State Transitions

```text
[Modified / Added]
       │
       ▼
Is path in .agents/** or .opencode/** ? ──(Yes)──► [Exempt / Skipped]
       │
      (No)
       ▼
[Lint Evaluated]
   ├── Clean ────────────────────► [No Action]
   ├── Auto-Fixable Violations ──► [Auto-Fixed via --fix] ──► [Committed to PR]
   └── Unfixable Violations ─────► [Reported in CI Log]
```

---

### 2. PullRequestEvent

Represents the CI trigger event when a Pull Request is submitted or revised.

| Field | Type | Description | Validation Rules |
| --- | --- | --- | --- |
| `pullRequestNumber` | `integer` | GitHub Pull Request identifier | Positive integer |
| `headRef` | `string` | Name of the source branch containing proposed changes | Non-empty string (e.g. `034-markdownlint-pr-autofix`) |
| `eventType` | `enum` | GitHub webhook action triggering the run | `opened`, `synchronize`, `reopened` |
| `isFork` | `boolean` | Whether the PR branch originates from a foreign fork | Derived from repository owner |
| `hasEligibleMarkdown` | `boolean` | Whether non-exempt Markdown files were modified | Calculated via path pattern filtering |

---

### 3. HostConfigurationProfile

Represents declarative operating targets managed by the repository.

| Field | Type | Target Scope | Package Integration Point |
| --- | --- | --- | --- |
| `desktop-pc` | NixOS (`x86_64-linux`) | System profile | `modules/core/base.nix` (`nixos.environment.systemPackages`) |
| `homelab` | NixOS (`x86_64-linux`) | System profile | `modules/core/base.nix` (`nixos.environment.systemPackages`) |
| `iso` | NixOS (`x86_64-linux`) | System profile | `modules/core/base.nix` (`nixos.environment.systemPackages`) |
| `macbook-air-m4-15` | Darwin (`aarch64-darwin`) | System profile | `modules/core/base.nix` (`darwin.environment.systemPackages`) |
| `devshell` | Multi-system developer shell | Shell buildInputs | `modules/core/devshell.nix` (`devShells.default.buildInputs`) |

---

### 4. AutoCommitRecord

Represents the Git revision generated when formatting modifications are performed automatically.

| Field | Type | Description |
| --- | --- | --- |
| `authorName` | `string` | `github-actions[bot]` |
| `authorEmail` | `string` | `github-actions[bot]@users.noreply.github.com` |
| `commitMessage` | `string` | `style(markdown): auto-format markdown files with markdownlint-cli2` |
| `modifiedFiles` | `list<string>` | List of adjusted files, guaranteed to exclude `.agents/**` and `.opencode/**` |
