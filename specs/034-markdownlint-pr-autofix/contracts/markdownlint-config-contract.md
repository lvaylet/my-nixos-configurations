# Contract: Markdownlint Configuration Schema

**File**: `.markdownlint-cli2.yaml`
**Purpose**: Centralized declarative configuration for `markdownlint-cli2` across CLI, local task runners, and CI workflows.

---

## 1. Schema & Structure

```yaml
# Declarative markdownlint-cli2 configuration for my-nixos-configurations
globs:
  - "**/*.md"

ignores:
  - ".agents/**"

config:
  default: true
```

---

## 2. Behavioral Guarantees

| Property | Directive | Enforcement |
| --- | --- | --- |
| **File Matching** | `globs: ["**/*.md"]` | Matches all Markdown documentation across the entire repository tree. |
| **Directory Exemption** | `ignores: [".agents/**"]` | Strictly ignores the `.agents` subfolder and all its nested files during discovery and linting passes. |
| **Rule Baseline** | `config.default: true` | Applies official standard markdownlint rules. |

---

## 3. Integration Points

- **CLI Tooling**: Invocations of `markdownlint-cli2` without explicit glob arguments will default to the patterns defined in this configuration file.
- **Auto-Fix Mode**: Invocations of `markdownlint-cli2 --fix` will mutate only matching files that are not excluded by `ignores`.
- **Editor Parity**: Editor extensions supporting `markdownlint-cli2` (e.g. VS Code, Neovim) honor `.markdownlint-cli2.yaml` at the project root.
