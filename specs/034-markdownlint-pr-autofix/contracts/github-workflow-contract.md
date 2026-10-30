# Contract: GitHub Actions Markdown Auto-Fix Workflow

**File**: `.github/workflows/markdownlint-fix.yml`
**Purpose**: Execute automated formatting of Markdown files on Pull Requests and push fixes back to the PR branch.

---

## 1. Triggers & Event Filters

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
    paths:
      - '**.md'
      - '**.markdown'
```

- **Trigger Condition**: Any Pull Request targeting `main` that introduces or modifies Markdown documents.
- **Concurrency**:

  ```yaml
  concurrency:
    group: markdownlint-fix-${{ github.head_ref || github.ref_name }}
    cancel-in-progress: true
  ```

  Cancels redundant prior runs when rapid consecutive commits are pushed to the same PR branch.

---

## 2. Security & Permissions

```yaml
permissions:
  contents: write
```

- **Read Access**: Clones the source branch at `github.head_ref`.
- **Write Access**: Grants rights to push formatting commits directly back to the pull request branch.

---

## 3. Workflow Steps & Behavior Contract

| Step # | Action / Command | Expected Behavior |
| --- | --- | --- |
| 1 | `actions/checkout@v4` with `ref: ${{ github.head_ref }}` | Checks out the branch head with full Git history for committing. |
| 2 | `DeterminateSystems/nix-installer-action@v16` | Installs hermetic Nix package manager. |
| 3 | `DeterminateSystems/magic-nix-cache-action@v9` | Configures remote binary caching for instant evaluation. |
| 4 | `nix shell nixpkgs#markdownlint-cli2 -c markdownlint-cli2 --fix` | Runs markdownlint-cli2 with `--fix`. Reads root `.markdownlint-cli2.yaml` (respects `ignores: [".agents/**"]`). |
| 5 | `stefanzweifel/git-auto-commit-action@v5` | If changes detected: commits and pushes with message `style(markdown): auto-format markdown files with markdownlint-cli2`. If no changes: exits cleanly without creating empty commits. |

---

## 4. Failure Modes & Invariants

- **Invariant 1**: Files matching `.agents/**` MUST NEVER appear in `git status` modifications created by step 4.
- **Invariant 2**: If no formatting issues exist, step 5 reports "No changes to commit" and exits with status 0.
- **Invariant 3**: If unfixable syntax violations exist, `markdownlint-cli2` outputs rule violations to standard error for developer visibility.
