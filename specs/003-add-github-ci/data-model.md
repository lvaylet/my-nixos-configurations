# Data Model: Modern Continuous Integration Pipeline

**Feature Branch**: `003-add-github-ci` | **Date**: 2026-08-12 | **Spec**: [spec.md](spec.md)

## Entity Relationship Overview

```mermaid
erDiagram
    CI_WORKFLOW ||--|{ TRIGGER_EVENT : responds_to
    CI_WORKFLOW ||--|| QUALITY_GATE_JOB : executes_first
    QUALITY_GATE_JOB ||--|{ MATRIX_BUILD_JOB : gates
    MATRIX_BUILD_JOB ||--|| BUILD_TARGET : builds
    QUALITY_GATE_JOB ||--|| BINARY_CACHE : reads_writes
    MATRIX_BUILD_JOB ||--|| BINARY_CACHE : reads_writes
    CI_WORKFLOW ||--|| STATUS_CHECK : reports

    CI_WORKFLOW {
        string name
        string path
        string permissions
        string concurrency_group
    }

    TRIGGER_EVENT {
        string event_type "pull_request | push | schedule | workflow_dispatch"
        string target_branch "main"
        string cron_expression "0 4 * * 1"
    }

    QUALITY_GATE_JOB {
        string id "check"
        string runner "ubuntu-latest"
        string command "nix flake check"
        string status "Pending | Running | Success | Failure | Skipped"
    }

    MATRIX_BUILD_JOB {
        string id "build"
        string runner "ubuntu-latest"
        string dependency "needs: check"
        string target "desktop-pc | homelab | iso"
        string status "Pending | Running | Success | Failure | Skipped"
    }

    BUILD_TARGET {
        string name "desktop-pc | homelab | iso"
        string attribute_path "nixosConfigurations.<name>.config.system.build.<attr>"
        string derivation_type "toplevel | isoImage"
    }

    BINARY_CACHE {
        string provider "Magic Nix Cache"
        string backend "GitHub Actions Cache API"
        string scope "Repository / Branch"
    }

    STATUS_CHECK {
        string commit_sha
        string state "success | failure | error | pending"
        string context "check / build (desktop-pc) / build (homelab) / build (iso)"
    }
```

---

## Entities & Attributes

### 1. `CI_WORKFLOW`

Represents the top-level GitHub Actions automation file (`.github/workflows/ci.yml`).

- **`name`** (string): Human-readable name displayed in GitHub UI (`CI`).
- **`path`** (string): Relative path from repo root (`.github/workflows/ci.yml`).
- **`permissions`** (map): Security permissions granted to the default `GITHUB_TOKEN` (`contents: read`).
- **`concurrency_group`** (string): Dynamic cancellation key (`${{ github.workflow }}-${{ github.ref }}`).
- **`cancel_in_progress`** (boolean): Automatically terminate superseded runs (`true`).

### 2. `TRIGGER_EVENT`

Represents the GitHub webhook and scheduling events that trigger pipeline execution.

- **`pull_request`**: Triggers on PR creation, synchronization (new commit), and reopening against `main`.
- **`push`**: Triggers on direct commits or merges pushed to `main`.
- **`schedule`**: Weekly scheduled run at Monday 04:00 UTC (`0 4 * * 1`).
- **`workflow_dispatch`**: Manual run triggered from GitHub Actions web interface or CLI.

### 3. `QUALITY_GATE_JOB` (`check`)

Initial fast verification stage executed on `ubuntu-latest`.

- **`runner`**: `ubuntu-latest` (x86_64 Linux).
- **`steps`**:
  1. `actions/checkout@v4`
  2. `DeterminateSystems/nix-installer-action@v16`
  3. `DeterminateSystems/magic-nix-cache-action@v9`
  4. `nix flake check`
- **`sub-checks executed hermetically`**:
  - `alejandra` (formatting validation)
  - `deadnix` (dead code detection)
  - `statix` (Nix antipattern and lint checking)
  - `flake-checker` (Nix flake health and best practices)
  - `trufflehog` + `ripsecrets` + `detect-private-keys` (secret leakage prevention)
  - `check-case-conflicts`, `check-executables-have-shebangs`, `trim-trailing-whitespace`, `end-of-file-fixer`, `mixed-line-endings` (repository hygiene)

### 4. `MATRIX_BUILD_JOB` (`build`)

Downstream parallel build jobs gated by `QUALITY_GATE_JOB`.

- **`dependency`**: `needs: [check]`
- **`runner`**: `ubuntu-latest`
- **`matrix`**:
  - `target: [desktop-pc, homelab, iso]`
- **`target mapping`**:
  - `desktop-pc` → `attribute: .#nixosConfigurations.desktop-pc.config.system.build.toplevel`
  - `homelab` → `attribute: .#nixosConfigurations.homelab.config.system.build.toplevel`
  - `iso` → `attribute: .#nixosConfigurations.iso.config.system.build.isoImage`

---

## State Transition & Execution Flow

```mermaid
stateDiagram-v2
    [*] --> Triggered: PR / Push / Schedule / Dispatch

    state Triggered {
        [*] --> InFlight: Cancel older runs in concurrency group
    }

    InFlight --> QualityGateCheck: Initialize Runner & Magic Nix Cache

    state QualityGateCheck {
        [*] --> FlakeCheck: nix flake check
        FlakeCheck --> LintPass: Formatting & Linters OK
        FlakeCheck --> SecretsPass: No Secrets Detected
        LintPass --> GateSuccess
        SecretsPass --> GateSuccess
    }

    QualityGateCheck --> GateFailed: Syntax / Lint / Secret Failure
    GateFailed --> [*]: Block PR & Abort Build Matrix

    GateSuccess --> BuildMatrix: Dispatch Parallel Runners

    state BuildMatrix {
        state "Build desktop-pc" as B1
        state "Build homelab" as B2
        state "Build iso" as B3

        [*] --> B1
        [*] --> B2
        [*] --> B3

        B1 --> B1_Done
        B2 --> B2_Done
        B3 --> B3_Done
    }

    BuildMatrix --> PipelineSuccess: All 3 Targets Built
    BuildMatrix --> PipelineFailed: Any Target Build Fails

    PipelineSuccess --> [*]: Green PR Status
    PipelineFailed --> [*]: Red PR Status with Target Failure Logs
```
